import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';

/// Session history screen — shows the shot ring buffer with a session summary
/// and a full shot log table.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ShotCubit, ShotState>(
        builder: (context, state) {
          if (state.history.isEmpty) return const _EmptyState();
          return _HistoryLayout(shots: state.history);
        },
      );
}

class _HistoryLayout extends StatelessWidget {
  const _HistoryLayout({required this.shots});

  final List<ShotDataModel> shots;

  @override
  Widget build(BuildContext context) {
    final avgCarry =
        shots.map((s) => s.carryYards).reduce((a, b) => a + b) / shots.length;
    final maxCarry =
        shots.map((s) => s.carryYards).reduce((a, b) => a > b ? a : b);
    final avgBall =
        shots.map((s) => s.ballSpeedMph).reduce((a, b) => a + b) / shots.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SessionSummaryCard(
            shotCount: shots.length,
            avgCarry: avgCarry,
            maxCarry: maxCarry,
            avgBallSpeed: avgBall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'SHOT LOG',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ShotLogTable(shots: shots),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session summary card
// ---------------------------------------------------------------------------

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({
    required this.shotCount,
    required this.avgCarry,
    required this.maxCarry,
    required this.avgBallSpeed,
  });

  final int shotCount;
  final double avgCarry;
  final double maxCarry;
  final double avgBallSpeed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(AppRadius.md),
        border: Border(
          left: BorderSide(color: AppColors.secondary, width: 4),
          top: BorderSide(color: AppColors.outlineVariant, width: 1),
          right: BorderSide(color: AppColors.outlineVariant, width: 1),
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SESSION SUMMARY', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'SHOTS',
                  value: '$shotCount',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'AVG CARRY',
                  value: '${avgCarry.toStringAsFixed(0)} yds',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'MAX CARRY',
                  value: '${maxCarry.toStringAsFixed(0)} yds',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'AVG BALL',
                  value: '${avgBallSpeed.toStringAsFixed(1)} mph',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shot log table
// ---------------------------------------------------------------------------

class _ShotLogTable extends StatelessWidget {
  const _ShotLogTable({required this.shots});

  final List<ShotDataModel> shots;

  static final _timeFmt = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text('TIME', style: theme.textTheme.labelSmall),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    'CLB',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'CARRY',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'BALL',
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
                    'LAUNCH',
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
            final isLast = i == shots.length - 1;
            final time = _timeFmt.format(s.dateTime.toLocal());
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
                        width: 52,
                        child: Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            s.clubId,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${s.carryYards.toStringAsFixed(0)} yds',
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
                          '${s.ballSpeedMph.toStringAsFixed(1)}',
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
                          '${s.launchAngleV.toStringAsFixed(1)}°',
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
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 48,
              color: AppColors.onSurfaceMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No history yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your session shots will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
}
