import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';

/// The Unity 3D Simulator screen.
///
/// Architecture:
///  1. [BlocListener<ShotCubit>] fires whenever a new shot arrives.
///  2. [_SimulatorScreenState] serialises it to JSON and calls postMessage
///     on the Unity object "BallPhysicsManager" → method "OnShotData".
///  3. Unity runs the ball flight simulation.
class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  UnityWidgetController? _unityController;
  bool _unityReady = false;

  void _onShot(ShotDataModel shot) {
    if (!_unityReady || _unityController == null) return;
    _unityController!.postMessage(
      'BallPhysicsManager',
      'OnShotData',
      jsonEncode(shot.toJson()),
    );
  }

  void _onUnityCreated(UnityWidgetController controller) {
    _unityController = controller;
  }

  void _onUnityMessage(dynamic message) {
    if (message == 'ready') setState(() => _unityReady = true);
  }

  void _onUnitySceneLoaded(SceneLoaded? _) {
    setState(() => _unityReady = true);
  }

  @override
  void dispose() {
    _unityController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ShotCubit, ShotState>(
        // Only fire when the latest shot actually changes.
        listenWhen: (prev, curr) => curr.latestShot != prev.latestShot,
        listener: (_, state) {
          if (state.latestShot != null) _onShot(state.latestShot!);
        },
        child: Stack(
          children: [
            UnityWidget(
              onUnityCreated: _onUnityCreated,
              onUnityMessage: _onUnityMessage,
              onUnitySceneLoaded: _onUnitySceneLoaded,
              useAndroidViewSurface: true,
              fullscreen: false,
            ),
            if (!_unityReady) const _LoadingOverlay(),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ShotOverlay(),
            ),
          ],
        ),
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
              const SizedBox(
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Shot data strip at the bottom of the simulator
// ---------------------------------------------------------------------------

class _ShotOverlay extends StatelessWidget {
  const _ShotOverlay();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ShotCubit, ShotState>(
        buildWhen: (prev, curr) => curr.latestShot != prev.latestShot,
        builder: (_, state) {
          if (!state.hasShot) return const SizedBox.shrink();
          return _ShotStrip(shot: state.latestShot!);
        },
      );
}

class _ShotStrip extends StatelessWidget {
  const _ShotStrip({required this.shot});

  final ShotDataModel shot;

  @override
  Widget build(BuildContext context) => Container(
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
              AppColors.background.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MiniStat(
              label: 'Carry',
              value: '${shot.carryYards.toStringAsFixed(0)} yds',
            ),
            _MiniStat(
              label: 'Ball',
              value: '${shot.ballSpeedMph.toStringAsFixed(1)} mph',
            ),
            _MiniStat(label: 'Spin', value: '${shot.spinRpm} rpm'),
            _MiniStat(
              label: 'Launch',
              value: '${shot.launchAngleV.toStringAsFixed(1)}°',
            ),
          ],
        ),
      );
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
