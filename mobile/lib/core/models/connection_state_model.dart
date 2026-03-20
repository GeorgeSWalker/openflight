import 'package:equatable/equatable.dart';

/// gRPC connection lifecycle state.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class ConnectionStateModel extends Equatable {
  const ConnectionStateModel({
    required this.status,
    this.host = '',
    this.port = 50051,
    this.lastError,
    this.lastPingMs,
  });

  final ConnectionStatus status;
  final String host;
  final int port;
  final String? lastError;

  /// Round-trip time from the last successful Ping RPC in milliseconds.
  final int? lastPingMs;

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;

  ConnectionStateModel copyWith({
    ConnectionStatus? status,
    String? host,
    int? port,
    String? lastError,
    int? lastPingMs,
  }) =>
      ConnectionStateModel(
        status: status ?? this.status,
        host: host ?? this.host,
        port: port ?? this.port,
        lastError: lastError ?? this.lastError,
        lastPingMs: lastPingMs ?? this.lastPingMs,
      );

  static const initial = ConnectionStateModel(
    status: ConnectionStatus.disconnected,
  );

  @override
  List<Object?> get props => [status, host, port, lastError, lastPingMs];
}
