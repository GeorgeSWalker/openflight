import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/providers/launch_monitor_provider.dart';

/// The Unity 3D Simulator screen.
///
/// Architecture:
///  1. Flutter receives gRPC [ShotDataModel] via [latestShotProvider].
///  2. The [_SimulatorScreenState] forwards the shot as a JSON postMessage
///     to the Unity object "BallPhysicsManager".
///  3. Unity runs the ball flight simulation.
///
/// The Unity project must implement a C# component on a GameObject named
/// "BallPhysicsManager" with a method "OnShotData(string json)".
class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen> {
  UnityWidgetController? _unityController;
  bool _unityReady = false;

  StreamSubscription<ShotDataModel>? _shotSub;

  @override
  void initState() {
    super.initState();
    _listenForShots();
  }

  @override
  void dispose() {
    _shotSub?.cancel();
    _unityController?.dispose();
    super.dispose();
  }

  void _listenForShots() {
    final client = ref.read(launchMonitorClientProvider);
    _shotSub = client.shots.listen(_onShot);
  }

  /// Serialise [shot] to JSON and post it to Unity's BallPhysicsManager.
  void _onShot(ShotDataModel shot) {
    if (!_unityReady || _unityController == null) return;
    final payload = jsonEncode(shot.toJson());
    _unityController!.postMessage(
      'BallPhysicsManager',
      'OnShotData',
      payload,
    );
  }

  void _onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
  }

  void _onUnityMessage(UnityWidgetController controller, String message) {
    // Unity → Flutter callbacks (e.g., "ready", "flightComplete") can be
    // handled here to update UI state.
    if (message == 'ready') {
      setState(() => _unityReady = true);
    }
  }

  void _onUnitySceneLoaded(SceneLoaded? scene) {
    setState(() => _unityReady = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _UnityViewport(
          onCreated: _onUnityCreated,
          onMessage: _onUnityMessage,
          onSceneLoaded: _onUnitySceneLoaded,
        ),
        if (!_unityReady) const _LoadingOverlay(),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _ShotOverlay(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Unity viewport
// ---------------------------------------------------------------------------

class _UnityViewport extends StatelessWidget {
  const _UnityViewport({
    required this.onCreated,
    required this.onMessage,
    required this.onSceneLoaded,
  });

  final void Function(UnityWidgetController) onCreated;
  final void Function(UnityWidgetController, String) onMessage;
  final void Function(SceneLoaded?) onSceneLoaded;

  @override
  Widget build(BuildContext context) => UnityWidget(
        onUnityCreated: onCreated,
        onUnityMessage: onMessage,
        onUnitySceneLoaded: onSceneLoaded,
        useAndroidViewSurface: true,
        fullscreen: false,
      );
}

// ---------------------------------------------------------------------------
// Loading overlay while Unity initialises
// ---------------------------------------------------------------------------

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Loading Simulator…',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
              ),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Shot data overlay strip at the bottom of the simulator
// ---------------------------------------------------------------------------

class _ShotOverlay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestShotProvider);

    return latest.when(
      data: (shot) => _ShotStrip(shot: shot),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ShotStrip extends StatelessWidget {
  const _ShotStrip({required this.shot});

  final ShotDataModel shot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            AppColors.background.withOpacity(0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
              label: 'Carry',
              value: '${shot.carryYards.toStringAsFixed(0)} yds'),
          _MiniStat(
              label: 'Ball',
              value: '${shot.ballSpeedMph.toStringAsFixed(1)} mph'),
          _MiniStat(label: 'Spin', value: '${shot.spinRpm} rpm'),
          _MiniStat(
              label: 'Launch',
              value: '${shot.launchAngleV.toStringAsFixed(1)}°'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      );
}
