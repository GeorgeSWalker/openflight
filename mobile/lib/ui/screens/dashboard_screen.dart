import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/bloc/target_distance/target_distance_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/ui/widgets/dispersion_canvas.dart';
import 'package:openflight_mobile/ui/widgets/stat_tile.dart';
import 'package:openflight_mobile/ui/widgets/waiting_for_swing.dart';

// ---------------------------------------------------------------------------
// Info text content
// ---------------------------------------------------------------------------

const _infoCarry =
    'How far the ball travels through the air before first touching the ground. '
    'Does not include roll after landing. The key number for club selection — '
    'if your 7-iron carries 150 yds consistently, you know exactly which club to reach for.';

const _infoBallSpeed =
    'How fast the ball leaves the clubface at impact. Ball speed is the biggest '
    'driver of carry distance. Tour pros average 160–175 mph with driver; '
    'amateur golfers typically see 100–140 mph.';

const _infoClubSpeed =
    'How fast the clubhead is moving at the moment it strikes the ball. '
    'Higher club speed requires a full shoulder turn, stored lag, and a fast '
    'release through impact. Tour pros average 110–125 mph with driver.';

const _infoSpin =
    'Backspin rate in revolutions per minute. More spin creates lift and height '
    'but reduces roll — and too much spin kills distance. For driver, aim for '
    '2,000–2,500 rpm. Irons typically produce 4,000–8,000 rpm. Very low spin '
    'can cause the ball to "fall out of the sky" early.';

const _infoLaunchV =
    'The upward angle the ball launches from the ground, in degrees. '
    'A higher launch angle gives more height and carry. '
    'For driver, the optimal window is roughly 10–16°. '
    'Pair this with spin: high launch + low spin = ideal driver ball flight.';

const _infoLaunchH =
    'The sideways direction the ball starts, relative to your target line. '
    '0° means the ball launched dead straight. Positive = right of target, '
    'negative = left. Compare with where the ball actually lands to understand '
    'your curvature (draw, fade, push, pull).';

const _infoSmash =
    'Ball Speed ÷ Club Speed. Measures how efficiently you transferred energy '
    'from the club to the ball. The theoretical maximum for a driver is 1.50 — '
    'anything above 1.45 is excellent. A lower number suggests off-centre '
    'contact or a poorly fitted club.';

const _infoDispersion =
    'A bird\'s-eye view showing where your last shots landed relative to the '
    'target flag. Tight clusters = consistent striking. Spread-out dots = '
    'variable distance or direction. Use the slider below to set your target distance.';

const _infoTarget =
    'The distance you\'re trying to hit. Adjust the slider to match your '
    'intended carry target. The flag in the dispersion chart moves to this '
    'distance so you can instantly see whether your shots are landing on target.';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Primary stats dashboard — shows the latest shot metrics and dispersion view.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ShotCubit, ShotState>(
        builder: (context, shotState) {
          if (!shotState.hasShot) return const WaitingForSwing();
          return BlocBuilder<TargetDistanceCubit, double>(
            builder: (context, target) => _DashboardLayout(
              shot: shotState.latestShot!,
              history: shotState.history,
              targetDistanceYards: target,
            ),
          );
        },
      );
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
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatsGrid(shot: shot),
            const SizedBox(height: AppSpacing.md),
            const _SectionLabel(label: 'Dispersion', infoText: _infoDispersion),
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
  Widget build(BuildContext context) => Row(
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
                  const _SectionLabel(
                    label: 'Dispersion',
                    infoText: _infoDispersion,
                  ),
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
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                label: 'Carry',
                value: _fmt(shot.carryYards, decimals: 0),
                unit: 'yds',
                highlighted: true,
                icon: Icons.flag_outlined,
                infoText: _infoCarry,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Ball Speed',
                value: _fmt(shot.ballSpeedMph),
                unit: 'mph',
                icon: Icons.speed_outlined,
                infoText: _infoBallSpeed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                label: 'Club Speed',
                value: _fmt(shot.clubSpeedMph),
                unit: 'mph',
                icon: Icons.sports_golf_outlined,
                infoText: _infoClubSpeed,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Spin',
                value: shot.spinRpm.toString(),
                unit: 'rpm',
                icon: Icons.rotate_right_outlined,
                infoText: _infoSpin,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                label: 'Launch V',
                value: _fmt(shot.launchAngleV),
                unit: '°',
                icon: Icons.trending_up_outlined,
                infoText: _infoLaunchV,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Launch H',
                value: _fmt(shot.launchAngleH),
                unit: '°',
                icon: Icons.swap_horiz_outlined,
                infoText: _infoLaunchH,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Smash',
                value: smash != null ? smash.toStringAsFixed(2) : '—',
                icon: Icons.bolt_outlined,
                infoText: _infoSmash,
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

class _TargetDistanceSlider extends StatelessWidget {
  const _TargetDistanceSlider({required this.targetDistanceYards});

  final double targetDistanceYards;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            label: 'Target: ${targetDistanceYards.toStringAsFixed(0)} yds',
            infoText: _infoTarget,
          ),
          Slider(
            value: targetDistanceYards.clamp(50.0, 300.0),
            min: 50,
            max: 300,
            divisions: 50,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.divider,
            onChanged: (v) =>
                context.read<TargetDistanceCubit>().setDistance(v),
          ),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.infoText});

  final String label;
  final String? infoText;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (infoText != null) ...[
            const SizedBox(width: AppSpacing.xs),
            InfoButton(title: label, text: infoText!),
          ],
        ],
      );
}
