import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:openflight_mobile/bloc/session/session_cubit.dart';
import 'package:openflight_mobile/bloc/settings/settings_cubit.dart';
import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/core/utils/unit_converter.dart';
import 'package:openflight_mobile/services/session_service.dart'
    show SessionRecord;

// ---------------------------------------------------------------------------
// Time range filter enum
// ---------------------------------------------------------------------------

enum _TimeRange {
  allTime('All time'),
  thisMonth('Month'),
  thisWeek('Week'),
  today('Today');

  const _TimeRange(this.label);
  final String label;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Club comparison screen — groups shot history by club and shows per-club
/// averages for carry, ball speed, spin, and smash factor.
///
/// Shots are drawn from both the live ring-buffer ([ShotCubit]) and all
/// saved sessions ([SessionCubit]), so comparisons include historical data.
/// Users can narrow by time range or a specific club.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  _TimeRange _range = _TimeRange.allTime;
  String? _filterClub; // null → all clubs

  /// Combine live ring-buffer shots with all saved session shots.
  /// Deduplication is by timestamp to avoid double-counting shots that
  /// appeared in the live buffer and were later saved to a session.
  List<ShotDataModel> _combineShots(
    List<ShotDataModel> live,
    List<SessionRecord> saved,
  ) {
    final seen = <int>{};
    final all = <ShotDataModel>[];
    for (final s in live) {
      if (seen.add(s.timestamp)) all.add(s);
    }
    for (final session in saved) {
      for (final s in session.shots) {
        if (seen.add(s.timestamp)) all.add(s);
      }
    }
    return all;
  }

  DateTime? _cutoff() {
    final now = DateTime.now();
    return switch (_range) {
      _TimeRange.allTime => null,
      _TimeRange.thisMonth => now.subtract(const Duration(days: 30)),
      _TimeRange.thisWeek => now.subtract(const Duration(days: 7)),
      _TimeRange.today => DateTime(now.year, now.month, now.day),
    };
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) =>
            BlocBuilder<ShotCubit, ShotState>(
          builder: (context, shotState) =>
              BlocBuilder<SessionCubit, SessionState>(
            builder: (context, sessionState) {
              final combined = _combineShots(
                shotState.history,
                sessionState.savedSessions,
              );

              // Apply time filter
              final cutoff = _cutoff();
              final timeFiltered = cutoff == null
                  ? combined
                  : combined
                      .where((s) => s.dateTime.isAfter(cutoff))
                      .toList();

              // All clubs present in time-filtered set (for filter chips)
              final availableClubs = timeFiltered
                  .map((s) => s.clubId)
                  .toSet()
                  .toList()
                ..sort();

              // Apply club filter on top
              final shots = _filterClub == null
                  ? timeFiltered
                  : timeFiltered
                      .where((s) => s.clubId == _filterClub)
                      .toList();

              if (shots.isEmpty && combined.isEmpty) {
                return const _EmptyState();
              }

              final groups = shots.isEmpty
                  ? <String, _ClubStats>{}
                  : _groupByClub(shots);

              return _CompareLayout(
                groups: groups,
                metric: settings.metric,
                timeRange: _range,
                filterClub: _filterClub,
                availableClubs: availableClubs,
                onRangeChanged: (r) =>
                    setState(() {
                      _range = r;
                      _filterClub = null; // reset club filter on range change
                    }),
                onClubChanged: (c) => setState(() => _filterClub = c),
              );
            },
          ),
        ),
      );

  static Map<String, _ClubStats> _groupByClub(List<ShotDataModel> shots) {
    final map = <String, List<ShotDataModel>>{};
    for (final shot in shots) {
      map.putIfAbsent(shot.clubId, () => []).add(shot);
    }
    return map.map((clubId, clubShots) => MapEntry(
          clubId,
          _ClubStats.fromShots(clubId, clubShots),
        ));
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _ClubStats {
  const _ClubStats({
    required this.clubId,
    required this.shotCount,
    required this.avgCarry,
    required this.maxCarry,
    required this.avgBallSpeed,
    required this.avgSpin,
    required this.avgSmash,
  });

  factory _ClubStats.fromShots(String clubId, List<ShotDataModel> shots) {
    final n = shots.length;
    final avgCarry =
        shots.map((s) => s.carryYards).reduce((a, b) => a + b) / n;
    final maxCarry = shots
        .map((s) => s.carryYards)
        .reduce((a, b) => a > b ? a : b);
    final avgBall =
        shots.map((s) => s.ballSpeedMph).reduce((a, b) => a + b) / n;
    final avgSpin =
        shots.map((s) => s.spinRpm).reduce((a, b) => a + b) / n;
    final smashes = shots.where((s) => s.smashFactor != null).toList();
    final avgSmash = smashes.isEmpty
        ? null
        : smashes.map((s) => s.smashFactor!).reduce((a, b) => a + b) /
            smashes.length;

    return _ClubStats(
      clubId: clubId,
      shotCount: n,
      avgCarry: avgCarry,
      maxCarry: maxCarry,
      avgBallSpeed: avgBall,
      avgSpin: avgSpin,
      avgSmash: avgSmash,
    );
  }

  final String clubId;
  final int shotCount;
  final double avgCarry;
  final double maxCarry;
  final double avgBallSpeed;
  final double avgSpin;
  final double? avgSmash;
}

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------

class _CompareLayout extends StatelessWidget {
  const _CompareLayout({
    required this.groups,
    required this.metric,
    required this.timeRange,
    required this.filterClub,
    required this.availableClubs,
    required this.onRangeChanged,
    required this.onClubChanged,
  });

  final Map<String, _ClubStats> groups;
  final bool metric;
  final _TimeRange timeRange;
  final String? filterClub;
  final List<String> availableClubs;
  final ValueChanged<_TimeRange> onRangeChanged;
  final ValueChanged<String?> onClubChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = groups.values.toList()
      ..sort((a, b) => b.avgCarry.compareTo(a.avgCarry));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterBar(
            timeRange: timeRange,
            filterClub: filterClub,
            availableClubs: availableClubs,
            onRangeChanged: onRangeChanged,
            onClubChanged: onClubChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          if (sorted.isEmpty)
            _NoResultsHint(timeRange: timeRange, filterClub: filterClub)
          else ...[
            _SummaryHeader(count: sorted.length),
            const SizedBox(height: AppSpacing.md),
            _BestClubCard(stats: sorted.first, metric: metric),
            const SizedBox(height: AppSpacing.md),
            _ClubTable(clubs: sorted, metric: metric),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.timeRange,
    required this.filterClub,
    required this.availableClubs,
    required this.onRangeChanged,
    required this.onClubChanged,
  });

  final _TimeRange timeRange;
  final String? filterClub;
  final List<String> availableClubs;
  final ValueChanged<_TimeRange> onRangeChanged;
  final ValueChanged<String?> onClubChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time range row
        Row(
          children: _TimeRange.values.map((r) {
            final selected = r == timeRange;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => onRangeChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.surfaceContainerLow,
                    borderRadius: const BorderRadius.all(AppRadius.sm),
                    border: Border.all(
                      color: selected
                          ? AppColors.accent
                          : AppColors.outlineVariant,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    r.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? AppColors.accent
                          : AppColors.onSurfaceMuted,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (availableClubs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          // Club filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" chip
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _ClubFilterChip(
                    label: 'All',
                    selected: filterClub == null,
                    onTap: () => onClubChanged(null),
                  ),
                ),
                ...availableClubs.map((id) => Padding(
                      padding:
                          const EdgeInsets.only(right: AppSpacing.xs),
                      child: _ClubFilterChip(
                        label: id,
                        selected: filterClub == id,
                        onTap: () => onClubChanged(
                          filterClub == id ? null : id,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ClubFilterChip extends StatelessWidget {
  const _ClubFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: const BorderRadius.all(AppRadius.sm),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : AppColors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.accent : AppColors.onSurfaceMuted,
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// No results hint (when filter yields nothing)
// ---------------------------------------------------------------------------

class _NoResultsHint extends StatelessWidget {
  const _NoResultsHint({required this.timeRange, required this.filterClub});

  final _TimeRange timeRange;
  final String? filterClub;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (timeRange != _TimeRange.allTime) parts.add(timeRange.label);
    if (filterClub != null) parts.add(filterClub!);
    final desc = parts.isEmpty ? '' : ' for ${parts.join(' · ')}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 40,
              color: AppColors.onSurfaceMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No shots$desc',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Text(
        '$count club${count == 1 ? '' : 's'} tracked',
        style: Theme.of(context).textTheme.bodyMedium,
      );
}

// ---------------------------------------------------------------------------
// Best club hero card
// ---------------------------------------------------------------------------

class _BestClubCard extends StatelessWidget {
  const _BestClubCard({required this.stats, required this.metric});

  final _ClubStats stats;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
              right: -8,
              bottom: -8,
              child: Icon(
                Icons.sports_golf_outlined,
                size: 96,
                color: AppColors.onSurface.withValues(alpha: 0.04),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LONGEST AVERAGE',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              UnitConverter.carryValue(
                                stats.avgCarry,
                                metric: metric,
                              ),
                              style:
                                  theme.textTheme.displayLarge?.copyWith(
                                color: AppColors.accent,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${UnitConverter.carryUnit(metric: metric)} avg',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Max ${UnitConverter.carry(stats.maxCarry, metric: metric)} · '
                          '${stats.shotCount} shot${stats.shotCount == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius:
                          const BorderRadius.all(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Text(
                      stats.clubId,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Club comparison table
// ---------------------------------------------------------------------------

class _ClubTable extends StatelessWidget {
  const _ClubTable({required this.clubs, required this.metric});

  final List<_ClubStats> clubs;
  final bool metric;

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
                  width: 40,
                  child: Text('CLB', style: theme.textTheme.labelSmall),
                ),
                Expanded(
                  child: Text(
                    'AVG (${UnitConverter.carryUnit(metric: metric)})',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'MAX (${UnitConverter.carryUnit(metric: metric)})',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    UnitConverter.speedUnit(metric: metric).toUpperCase(),
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
                SizedBox(
                  width: 28,
                  child: Text(
                    '#',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          ...clubs.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isLast = i == clubs.length - 1;
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
                        width: 40,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent
                                .withValues(alpha: 0.12),
                            borderRadius: const BorderRadius.all(
                                Radius.circular(4)),
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
                          UnitConverter.carryValue(
                            s.avgCarry,
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
                          UnitConverter.carryValue(
                            s.maxCarry,
                            metric: metric,
                          ),
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
                          UnitConverter.speedValue(
                            s.avgBallSpeed,
                            metric: metric,
                          ),
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
                          s.avgSmash != null
                              ? s.avgSmash!.toStringAsFixed(2)
                              : '—',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${s.shotCount}',
                          style: theme.textTheme.bodySmall,
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
              Icons.bar_chart_outlined,
              size: 48,
              color: AppColors.onSurfaceMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No shots yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hit a few shots to compare clubs',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
}
