import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/providers/launch_monitor_provider.dart';
import 'package:openflight_mobile/ui/widgets/dispersion_canvas.dart';
import 'package:openflight_mobile/ui/widgets/stat_tile.dart';
import 'package:openflight_mobile/ui/widgets/waiting_for_swing.dart';

/// Primary stats dashboard — shows the latest shot metrics and dispersion view.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestShotProvider);
    final history = ref.watch(shotHistoryProvider);
    final target = ref.watch(targetDistanceProvider);

    return latestAsync.when(
      data: (shot) => _DashboardLayout(
        shot: shot,
        history: history,
        targetDistanceYards: target,
      ),
      loading: () => const WaitingForSwing(),
      error: (_, __) => const WaitingForSwing(),
    );
  }
}

class _DashboardLayout extends StatelessWidget {
  const _DashboardLayout({
    required this.shot,
    required this.history,
    required this.targetDistanceYards,
  });

  final ShotDataModel shot;
  final List<ShotDataModel> history;
  final double targetDistanceYards;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return isLandscape
        ? _LandscapeLayout(
            shot: shot,
            history: history,
            targetDistanceYards: targetDistanceYards,
          )
        : _PortraitLayout(
            shot: shot,
            history: history,
            targetDistanceYards: targetDistanceYards,
          );
  }
}

// ---------------------------------------------------------------------------
// Portrait
// ---------------------------------------------------------------------------

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({
    required this.shot,
    required this.history,
    required this.targetDistanceYards,
  });

  final ShotDataModel shot;
  final List<ShotDataModel> history;
  final double targetDistanceYards;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsGrid(shot: shot),
          const SizedBox(height: AppSpacing.md),
          _SectionLabel(label: 'Dispersion'),
          const SizedBox(height: AppSpacing.sm),
          DispersionCanvas(
            history: history,
            targetDistanceYards: targetDistanceYards,
          ),
          const SizedBox(height: AppSpacing.md),
          _TargetDistanceSlider(targetDistanceYards: targetDistanceYards),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Landscape (tablet / kiosk)
// ---------------------------------------------------------------------------

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({
    required this.shot,
    required this.history,
    required this.targetDistanceYards,
  });

  final ShotDataModel shot;
  final List<ShotDataModel> history;
  final double targetDistanceYards;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _StatsGrid(shot: shot),
                const SizedBox(height: AppSpacing.md),
                _TargetDistanceSlider(
                    targetDistanceYards: targetDistanceYards),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.divider),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(label: 'Dispersion'),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: DispersionCanvas(
                    history: history,
                    targetDistanceYards: targetDistanceYards,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats grid
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.shot});

  final ShotDataModel shot;

  String _fmt(double v, {int decimals = 1}) => v.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    final smash = shot.smashFactor;

    return Column(
      children: [
        // Row 1: primary metrics (larger)
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                label: 'Carry',
                value: _fmt(shot.carryYards, decimals: 0),
                unit: 'yds',
                highlighted: true,
                icon: Icons.flag_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Ball Speed',
                value: _fmt(shot.ballSpeedMph),
                unit: 'mph',
                icon: Icons.speed_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Row 2
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                label: 'Club Speed',
                value: _fmt(shot.clubSpeedMph),
                unit: 'mph',
                icon: Icons.sports_golf_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Spin',
                value: shot.spinRpm.toString(),
                unit: 'rpm',
                icon: Icons.rotate_right_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Row 3
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                label: 'Launch V',
                value: _fmt(shot.launchAngleV),
                unit: '°',
                icon: Icons.trending_up_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Launch H',
                value: _fmt(shot.launchAngleH),
                unit: '°',
                icon: Icons.swap_horiz_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Smash',
                value: smash != null ? smash.toStringAsFixed(2) : '—',
                icon: Icons.bolt_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Target distance slider
// ---------------------------------------------------------------------------

class _TargetDistanceSlider extends ConsumerWidget {
  const _TargetDistanceSlider({required this.targetDistanceYards});

  final double targetDistanceYards;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            label: 'Target: ${targetDistanceYards.toStringAsFixed(0)} yds',
          ),
          Slider(
            value: targetDistanceYards.clamp(50.0, 300.0),
            min: 50,
            max: 300,
            divisions: 50,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.divider,
            onChanged: (v) =>
                ref.read(targetDistanceProvider.notifier).setDistance(v),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      );
}
