import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/services/launch_monitor_client.dart';

/// Tracks the currently selected club and syncs changes to the Pi via gRPC.
///
/// State is a plain [String] (club ID, e.g. "DR", "7I").
class ClubCubit extends Cubit<String> {
  ClubCubit(this._client) : super('DR');

  final LaunchMonitorClient _client;

  /// Select [clubId] and fire the gRPC UpdateConfig RPC.
  Future<void> select(String clubId, {double targetDistanceYards = 0}) async {
    emit(clubId);
    await _client.updateConfig(
      clubId: clubId,
      targetDistanceYards: targetDistanceYards,
    );
  }
}
