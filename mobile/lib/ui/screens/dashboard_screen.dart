import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:openflight_mobile/bloc/session/session_cubit.dart';
import 'package:openflight_mobile/bloc/settings/settings_cubit.dart';
import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/bloc/target_distance/target_distance_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/core/utils/unit_converter.dart';
import 'package:openflight_mobile/ui/widgets/dispersion_canvas.dart';
import 'package:openflight_mobile/ui/widgets/stat_tile.dart';
import 'package:openflight_mobile/ui/widgets/waiting_for_swing.dart';

// ---------------------------------------------------------------------------
// Info text constants
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
    '2,000–2,500 rpm. Irons typically produce 4,000–8,000 rpm.';

const _infoLaunchV =
    'The upward angle the ball launches from the ground, in degrees. '
    'For driver, the optimal window is roughly 10–16°. '
    'Pair this with spin: high launch + low spin = ideal driver ball flight.';

const _infoLaunchH =
    'The sideways direction the ball starts, relative to your target line. '
    '0° means the ball launched dead straight. Positive = right of target, '
    'negative = left. Compare with where the ball lands to understand curvature.';

const _infoSmash =
    'Ball Speed ÷ Club Speed. Measures how efficiently you transferred energy '
    'from the club to the ball. The theoretical maximum for a driver is 1.50 — '
    'anything above 1.45 is excellent.';

const _infoDispersion =
    'A bird\'s-eye view showing where your last shots landed relative to the '
    'target flag. Tap any dot to see the full breakdown for that shot.';

const _infoTarget =
    'The distance you\'re trying to hit. Adjust the slider to match your '
    'intended carry target. The flag moves to this distance in the chart.';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ShotCubit, ShotState>(
        builder: (context, shotState) {
          if (!shotState.hasShot) return const WaitingForSwing();
          return BlocBuilder<TargetDistanceCubit, double>(
            builder: (context, target) =>
                BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settings) => _DashboardLayout(
                shot: shotState.latestShot!,
                history: shotState.history,
                targetDistanceYards: target,
                metric: settings.metric,
              ),
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
    required this.metric,
  });

  final ShotDataModel shot;
  final List<ShotDataModel> history;
  final double targetDistanceYards;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape
        ? _LandscapeLayout(
            shot: shot,
            history: history,
            targetDistanceYards: targetDistanceYards,
            metric: metric,
          )
        : _PortraitLayout(
            shot: shot,
            history: history,
            targetDistanceYards: targetDistanceYards,
            metric: metric,
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
    required this.metric,
  });

  final ShotDataModel shot;
  final List<ShotDataModel> history;
  final double targetDistanceYards;
  final bool metric;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RecordingBanner(),
            _HeroCarryCard(shot: shot, metric: metric),
            const SizedBox(height: AppSpacing.sm),
            _SecondaryGrid(shot: shot, metric: metric),
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(label: 'Dispersion', infoText: _infoDispersion),
            const SizedBox(height: AppSpacing.sm),
            DispersionCanvas(
              history: history,
              targetDistanceYards: targetDistanceYards,
            ),
            const SizedBox(height: AppSpacing.sm),
            _TargetDistanceSlider(
              targetDistanceYards: targetDistanceYards,
              metric: metric,
            ),
            if (history.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              const _SectionHeader(label: 'Recent Shots'),
              const SizedBox(height: AppSpacing.sm),
              _RecentShotsTable(history: history, metric: metric),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Landscape
// ---------------------------------------------------------------------------

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({
    required this.shot,
    required this.history,
    required this.targetDistanceYards,
    required this.metric,
  });

  final ShotDataModel shot;
  final List<ShotDataModel> history;
  final double targetDistanceYards;
  final bool metric;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RecordingBanner(),
                  _HeroCarryCard(shot: shot, metric: metric),
                  const SizedBox(height: AppSpacing.sm),
                  _SecondaryGrid(shot: shot, metric: metric),
                  const SizedBox(height: AppSpacing.sm),
                  _TargetDistanceSlider(
                    targetDistanceYards: targetDistanceYards,
                    metric: metric,
                  ),
                  if (history.length > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _SectionHeader(label: 'Recent Shots'),
                    const SizedBox(height: AppSpacing.sm),
                    _RecentShotsTable(history: history, metric: metric),
                  ],
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
                  _SectionHeader(
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
// Recording banner
// ---------------------------------------------------------------------------

class _RecordingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCubit, SessionState>(
        builder: (_, state) {
          if (state.activeSession == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(AppRadius.sm),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Recording session · '
                    '${state.activeSession!.shotCount} shots',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<SessionCubit>().endSession(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                  child: const Text('End'),
                ),
              ],
            ),
          );
        },
      );
}

// ---------------------------------------------------------------------------
// Hero carry card
// ---------------------------------------------------------------------------

class _HeroCarryCard extends StatelessWidget {
  const _HeroCarryCard({required this.shot, required this.metric});

  final ShotDataModel shot;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(AppRadius.md),
        border: Border(
          left: BorderSide(color: AppColors.accent, width: 4),
          top: BorderSide(color: AppColors.outlineVariant, width: 1),
          right: BorderSide(color: AppColors.outlineVariant, width: 1),
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(AppRadius.md),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                Icons.flag_outlined,
                size: 120,
                color: AppColors.onSurface.withValues(alpha: 0.04),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 11,
                              color: AppColors.onSurfaceMuted,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'CARRY',
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            InfoButton(
                              title: 'Carry',
                              text: _infoCarry,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              UnitConverter.carryValue(
                                shot.carryYards,
                                metric: metric,
                              ),
                              style: theme.textTheme.displayLarge?.copyWith(
                                color: AppColors.accent,
                                fontSize: 64,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                UnitConverter.carryUnit(metric: metric),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurfaceMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Ball ${UnitConverter.speed(shot.ballSpeedMph, metric: metric)}'
                          '  ·  Club ${UnitConverter.speed(shot.clubSpeedMph, metric: metric)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _ClubBadge(clubId: shot.clubId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubBadge extends StatelessWidget {
  const _ClubBadge({required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(AppRadius.sm),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.30),
          ),
        ),
        child: Text(
          clubId,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Secondary grid
// ---------------------------------------------------------------------------

class _SecondaryGrid extends StatelessWidget {
  const _SecondaryGrid({required this.shot, required this.metric});

  final ShotDataModel shot;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final smash = shot.smashFactor;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                label: 'Ball Speed',
                value: UnitConverter.speedValue(
                  shot.ballSpeedMph,
                  metric: metric,
                ),
                unit: UnitConverter.speedUnit(metric: metric),
                icon: Icons.speed_outlined,
                infoText: _infoBallSpeed,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Club Speed',
                value: UnitConverter.speedValue(
                  shot.clubSpeedMph,
                  metric: metric,
                ),
                unit: UnitConverter.speedUnit(metric: metric),
                icon: Icons.sports_golf_outlined,
                infoText: _infoClubSpeed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                label: 'Spin',
                value: shot.spinRpm.toString(),
                unit: 'rpm',
                icon: Icons.rotate_right_outlined,
                infoText: _infoSpin,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Smash Factor',
                value: smash != null ? smash.toStringAsFixed(2) : '—',
                icon: Icons.bolt_outlined,
                infoText: _infoSmash,
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
                value: shot.launchAngleV.toStringAsFixed(1),
                unit: '°',
                icon: Icons.trending_up_outlined,
                infoText: _infoLaunchV,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedStatTile(
                label: 'Launch H',
                value: shot.launchAngleH.toStringAsFixed(1),
                unit: '°',
                icon: Icons.swap_horiz_outlined,
                infoText: _infoLaunchH,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Target slider
// ---------------------------------------------------------------------------

class _TargetDistanceSlider extends StatelessWidget {
  const _TargetDistanceSlider({
    required this.targetDistanceYards,
    required this.metric,
  });

  final double targetDistanceYards;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final display = UnitConverter.targetDisplay(
      targetDistanceYards,
      metric: metric,
    );
    final unit = UnitConverter.targetUnit(metric: metric);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: 'Target: ${display.toStringAsFixed(0)} $unit',
          infoText: _infoTarget,
        ),
        Slider(
          value: display.clamp(
            UnitConverter.targetMin(metric: metric),
            UnitConverter.targetMax(metric: metric),
          ),
          min: UnitConverter.targetMin(metric: metric),
          max: UnitConverter.targetMax(metric: metric),
          divisions: 50,
          onChanged: (v) {
            final yards =
                UnitConverter.targetToYards(v, metric: metric);
            context.read<TargetDistanceCubit>().setDistance(yards);
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recent shots table
// ---------------------------------------------------------------------------

class _RecentShotsTable extends StatelessWidget {
  const _RecentShotsTable({required this.history, required this.metric});

  final List<ShotDataModel> history;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shots = history.take(8).toList();
    final speedUnit = UnitConverter.speedUnit(metric: metric);
    final carryUnit = UnitConverter.carryUnit(metric: metric);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(AppRadius.md),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text('CLB', style: theme.textTheme.labelSmall),
                ),
                Expanded(
                  child: Text(
                    'CARRY ($carryUnit)',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'BALL ($speedUnit)',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'SPIN',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'SMASH',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          ...shots.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final smash = s.smashFactor;
            final isLast = i == shots.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: _MiniClubBadge(clubId: s.clubId),
                      ),
                      Expanded(
                        child: Text(
                          UnitConverter.carryValue(
                            s.carryYards,
                            metric: metric,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurface,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          UnitConverter.speedValue(
                            s.ballSpeedMph,
                            metric: metric,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurface,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${s.spinRpm}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          smash != null ? smash.toStringAsFixed(2) : '—',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    color: AppColors.divider,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _MiniClubBadge extends StatelessWidget {
  const _MiniClubBadge({required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(
          clubId,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
          textAlign: TextAlign.center,
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.infoText});

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
