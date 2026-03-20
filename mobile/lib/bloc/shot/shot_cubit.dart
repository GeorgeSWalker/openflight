import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/bloc/shot/shot_state.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';

export 'package:openflight_mobile/bloc/shot/shot_state.dart';

/// Accumulates shots streamed from [LaunchMonitorClient].
///
/// Emits [ShotState] on every new shot and when history is cleared.
class ShotCubit extends Cubit<ShotState> {
  static const int kMaxHistory = 20;

  ShotCubit(LaunchMonitorClient client) : super(ShotState.initial) {
    _sub = client.shots.listen(_onShot);
  }

  late final StreamSubscription<ShotDataModel> _sub;

  void _onShot(ShotDataModel shot) {
    final updated = [shot, ...state.history];
    emit(ShotState(
      latestShot: shot,
      history: updated.length > kMaxHistory
          ? updated.sublist(0, kMaxHistory)
          : updated,
    ));
  }

  void clearHistory() => emit(ShotState(latestShot: state.latestShot));

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
