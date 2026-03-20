import 'dart:async';

import 'package:grpc/grpc.dart';

import 'package:openflight_mobile/core/models/connection_state_model.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/proto/openflight.pb.dart';
import 'package:openflight_mobile/proto/openflight.pbgrpc.dart' as pbgrpc;

/// Default gRPC port for the OpenFlight Pi server.
const kDefaultGrpcPort = 50051;

/// Heartbeat interval for the Ping RPC.
const _kHeartbeatInterval = Duration(seconds: 5);

/// How long to wait before re-attempting a dropped stream.
const _kReconnectDelay = Duration(seconds: 3);

/// gRPC client for the OpenFlight LaunchMonitor service.
///
/// Lifecycle:
///   1. Call [connect] with the Pi's IP to open the channel.
///   2. Subscribe to [shots] to receive [ShotDataModel] objects in real-time.
///   3. Subscribe to [connectionState] to drive the connection indicator.
///   4. Call [updateConfig] to send club/target changes back to the Pi.
///   5. Call [dispose] when done (e.g., on app exit).
class LaunchMonitorClient {
  LaunchMonitorClient();

  ClientChannel? _channel;
  pbgrpc.LaunchMonitorClient? _stub;

  final _shotController = StreamController<ShotDataModel>.broadcast();
  final _stateController =
      StreamController<ConnectionStateModel>.broadcast();

  ConnectionStateModel _state = ConnectionStateModel.initial;

  Timer? _heartbeatTimer;
  StreamSubscription<ShotData>? _shotSubscription;
  bool _disposed = false;

  /// Broadcast stream of shots as they arrive from the Pi.
  Stream<ShotDataModel> get shots => _shotController.stream;

  /// Broadcast stream of connection lifecycle changes.
  Stream<ConnectionStateModel> get connectionState => _stateController.stream;

  /// Most recent connection state (synchronous access).
  ConnectionStateModel get currentState => _state;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Open the gRPC channel and begin streaming shots from [host]:[port].
  Future<void> connect({
    required String host,
    int port = kDefaultGrpcPort,
  }) async {
    if (_disposed) return;
    await _teardown();

    _updateState(
      _state.copyWith(
        status: ConnectionStatus.connecting,
        host: host,
        port: port,
        lastError: null,
      ),
    );

    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        idleTimeout: Duration(minutes: 5),
      ),
    );
    _stub = pbgrpc.LaunchMonitorClient(_channel!);

    try {
      await _ping(host: host, port: port);
      _startShotStream();
      _startHeartbeat();
    } on GrpcError catch (e) {
      _handleError(e.message ?? e.toString());
    } catch (e) {
      _handleError(e.toString());
    }
  }

  /// Disconnect cleanly.
  Future<void> disconnect() async {
    await _teardown();
    _updateState(ConnectionStateModel.initial);
  }

  /// Send a club/target configuration update to the Pi.
  ///
  /// Returns true on success, false if the RPC fails or we are not connected.
  Future<bool> updateConfig({
    required String clubId,
    double targetDistanceYards = 0,
  }) async {
    if (_stub == null || !_state.isConnected) return false;

    try {
      final response = await _stub!.updateConfig(
        UserConfig(
          currentClub: clubId,
          targetDistanceYards: targetDistanceYards,
        ),
        options: CallOptions(timeout: const Duration(seconds: 5)),
      );
      return response.success;
    } on GrpcError catch (e) {
      _handleError(e.message ?? e.toString());
      return false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _teardown();
    await _shotController.close();
    await _stateController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<void> _ping({required String host, required int port}) async {
    final sw = Stopwatch()..start();
    await _stub!.ping(
      Empty(),
      options: CallOptions(timeout: const Duration(seconds: 5)),
    );
    sw.stop();

    _updateState(
      _state.copyWith(
        status: ConnectionStatus.connected,
        host: host,
        port: port,
        lastPingMs: sw.elapsedMilliseconds,
        lastError: null,
      ),
    );
  }

  void _startShotStream() {
    _shotSubscription?.cancel();
    _shotSubscription = _stub!
        .streamShots(Empty())
        .listen(
          _onShotReceived,
          onError: _onStreamError,
          onDone: _onStreamDone,
        );
  }

  void _onShotReceived(ShotData proto) {
    if (_disposed) return;
    final model = _protoToModel(proto);
    _shotController.add(model);
  }

  void _onStreamError(Object error) {
    if (_disposed) return;
    final message =
        error is GrpcError ? (error.message ?? error.toString()) : '$error';
    _handleError(message);
  }

  void _onStreamDone() {
    if (_disposed || !_state.isConnected) return;
    // Server closed the stream — attempt reconnect after delay.
    Future.delayed(_kReconnectDelay, () {
      if (!_disposed && _state.isConnected) {
        _startShotStream();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_kHeartbeatInterval, (_) async {
      if (_disposed || _stub == null) return;
      try {
        final sw = Stopwatch()..start();
        await _stub!.ping(
          Empty(),
          options: CallOptions(timeout: const Duration(seconds: 3)),
        );
        sw.stop();
        if (_state.isConnected || _state.isConnecting) {
          _updateState(
            _state.copyWith(
              status: ConnectionStatus.connected,
              lastPingMs: sw.elapsedMilliseconds,
              lastError: null,
            ),
          );
        }
      } on GrpcError catch (e) {
        _handleError(e.message ?? e.toString());
      }
    });
  }

  void _handleError(String message) {
    _updateState(
      _state.copyWith(
        status: ConnectionStatus.error,
        lastError: message,
      ),
    );
    // Re-attempt connection after delay.
    Future.delayed(_kReconnectDelay, () {
      if (!_disposed && _state.status == ConnectionStatus.error) {
        connect(host: _state.host, port: _state.port);
      }
    });
  }

  Future<void> _teardown() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _shotSubscription?.cancel();
    _shotSubscription = null;
    _stub = null;
    await _channel?.shutdown();
    _channel = null;
  }

  void _updateState(ConnectionStateModel newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  // ---------------------------------------------------------------------------
  // Proto → Domain mapping
  // ---------------------------------------------------------------------------

  static ShotDataModel _protoToModel(ShotData proto) => ShotDataModel(
        ballSpeedMph: proto.ballSpeedMph.toDouble(),
        clubSpeedMph: proto.clubSpeedMph.toDouble(),
        launchAngleV: proto.launchAngleV.toDouble(),
        launchAngleH: proto.launchAngleH.toDouble(),
        spinRpm: proto.spinRpm,
        carryYards: proto.carryYards.toDouble(),
        clubId: proto.clubId,
        timestamp: proto.timestamp,
      );
}

// ---------------------------------------------------------------------------
// Stub client – identical API, emits mock shots on a timer. Used in tests
// and when running with --mock flag (no Pi hardware required).
// ---------------------------------------------------------------------------

class MockLaunchMonitorClient extends LaunchMonitorClient {
  MockLaunchMonitorClient({
    this.shotInterval = const Duration(seconds: 4),
  });

  final Duration shotInterval;

  Timer? _mockTimer;
  int _shotCount = 0;

  static const _mockShots = <ShotDataModel>[
    ShotDataModel(
      ballSpeedMph: 152.4,
      clubSpeedMph: 102.1,
      launchAngleV: 10.8,
      launchAngleH: 1.2,
      spinRpm: 2450,
      carryYards: 248.0,
      clubId: 'DR',
      timestamp: 0,
    ),
    ShotDataModel(
      ballSpeedMph: 128.7,
      clubSpeedMph: 89.3,
      launchAngleV: 15.2,
      launchAngleH: -0.8,
      spinRpm: 5820,
      carryYards: 178.0,
      clubId: '7I',
      timestamp: 0,
    ),
    ShotDataModel(
      ballSpeedMph: 140.1,
      clubSpeedMph: 95.5,
      launchAngleV: 12.5,
      launchAngleH: 2.1,
      spinRpm: 3100,
      carryYards: 215.0,
      clubId: '5W',
      timestamp: 0,
    ),
  ];

  @override
  Future<void> connect({
    required String host,
    int port = kDefaultGrpcPort,
  }) async {
    _updateStateMock(
      ConnectionStateModel(
        status: ConnectionStatus.connecting,
        host: host,
        port: port,
      ),
    );

    // Simulate connection delay.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    _updateStateMock(
      ConnectionStateModel(
        status: ConnectionStatus.connected,
        host: host,
        port: port,
        lastPingMs: 4,
      ),
    );

    _startMockStream();
  }

  void _startMockStream() {
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(shotInterval, (_) {
      final template = _mockShots[_shotCount % _mockShots.length];
      _shotCount++;
      final shot = template.copyWith(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        // Slightly vary values to look live.
        ballSpeedMph: template.ballSpeedMph + (_shotCount % 5) - 2.0,
        carryYards: template.carryYards + (_shotCount % 7) - 3.0,
        launchAngleH: template.launchAngleH + (_shotCount % 3) - 1.0,
      );
      if (!_shotController.isClosed) {
        _shotController.add(shot);
      }
    });
  }

  void _updateStateMock(ConnectionStateModel s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  @override
  Future<void> disconnect() async {
    _mockTimer?.cancel();
    _updateStateMock(ConnectionStateModel.initial);
  }

  @override
  Future<bool> updateConfig({
    required String clubId,
    double targetDistanceYards = 0,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return true;
  }

  @override
  Future<void> dispose() async {
    _mockTimer?.cancel();
    await super.dispose();
  }
}
