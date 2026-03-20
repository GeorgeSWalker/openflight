import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/core/models/connection_state_model.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';

export 'package:openflight_mobile/core/models/connection_state_model.dart';

/// Manages the gRPC connection lifecycle.
///
/// Emits [ConnectionStateModel] states.  All gRPC I/O is delegated to
/// [LaunchMonitorClient]; this cubit is purely a state adapter.
class ConnectionCubit extends Cubit<ConnectionStateModel> {
  ConnectionCubit(this._client) : super(ConnectionStateModel.initial) {
    // Mirror the client's own state stream into this cubit's state.
    _sub = _client.connectionState.listen(emit);
  }

  final LaunchMonitorClient _client;
  late final _sub = _client.connectionState.listen(emit);

  Future<void> connect({required String host, int port = kDefaultGrpcPort}) =>
      _client.connect(host: host, port: port);

  Future<void> disconnect() => _client.disconnect();

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
