import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openflight_mobile/core/models/connection_state_model.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/services/launch_monitor_client.dart';

// ---------------------------------------------------------------------------
// Client provider — single instance shared across the app.
// Swap for MockLaunchMonitorClient during development / testing.
// ---------------------------------------------------------------------------

final launchMonitorClientProvider = Provider<LaunchMonitorClient>((ref) {
  // Change to LaunchMonitorClient() when real hardware is available.
  final client = MockLaunchMonitorClient();
  ref.onDispose(client.dispose);
  return client;
});

// ---------------------------------------------------------------------------
// Connection state
// ---------------------------------------------------------------------------

final connectionStateProvider =
    StreamProvider<ConnectionStateModel>((ref) async* {
  final client = ref.watch(launchMonitorClientProvider);
  // Seed with the synchronous current state first so UI has an immediate value.
  yield client.currentState;
  yield* client.connectionState;
});

// ---------------------------------------------------------------------------
// Latest single shot
// ---------------------------------------------------------------------------

final latestShotProvider = StreamProvider<ShotDataModel>((ref) {
  return ref.watch(launchMonitorClientProvider).shots;
});

// ---------------------------------------------------------------------------
// Shot history — keeps last N shots for dispersion canvas.
// ---------------------------------------------------------------------------

const _kMaxHistory = 20;

final shotHistoryProvider =
    NotifierProvider<ShotHistoryNotifier, List<ShotDataModel>>(
  ShotHistoryNotifier.new,
);

class ShotHistoryNotifier extends Notifier<List<ShotDataModel>> {
  late StreamSubscription<ShotDataModel> _sub;

  @override
  List<ShotDataModel> build() {
    final client = ref.watch(launchMonitorClientProvider);
    _sub = client.shots.listen(_onShot);
    ref.onDispose(_sub.cancel);
    return [];
  }

  void _onShot(ShotDataModel shot) {
    final updated = [shot, ...state];
    state = updated.length > _kMaxHistory
        ? updated.sublist(0, _kMaxHistory)
        : updated;
  }

  void clear() => state = [];
}

// ---------------------------------------------------------------------------
// Selected club & target distance
// ---------------------------------------------------------------------------

final selectedClubProvider =
    NotifierProvider<SelectedClubNotifier, String>(SelectedClubNotifier.new);

class SelectedClubNotifier extends Notifier<String> {
  @override
  String build() => 'DR';

  /// Updates the selected club and fires the gRPC UpdateConfig RPC.
  Future<void> select(String clubId, {double targetDistanceYards = 0}) async {
    state = clubId;
    final client = ref.read(launchMonitorClientProvider);
    await client.updateConfig(
      clubId: clubId,
      targetDistanceYards: targetDistanceYards,
    );
  }
}

final targetDistanceProvider =
    NotifierProvider<TargetDistanceNotifier, double>(
  TargetDistanceNotifier.new,
);

class TargetDistanceNotifier extends Notifier<double> {
  @override
  double build() => 150.0; // yards

  void setDistance(double yards) => state = yards;
}

// ---------------------------------------------------------------------------
// App mode — which primary screen is active
// ---------------------------------------------------------------------------

enum AppMode { dashboard, simulator }

final appModeProvider =
    NotifierProvider<AppModeNotifier, AppMode>(AppModeNotifier.new);

class AppModeNotifier extends Notifier<AppMode> {
  @override
  AppMode build() => AppMode.dashboard;

  void switchTo(AppMode mode) => state = mode;
}
