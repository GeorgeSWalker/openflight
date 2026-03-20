import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:openflight_mobile/bloc/session/session_cubit.dart';
import 'package:openflight_mobile/bloc/settings/settings_cubit.dart';
import 'package:openflight_mobile/services/session_service.dart' show ClubSummary;
import 'package:openflight_mobile/bloc/shot/shot_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/core/utils/unit_converter.dart';
import 'package:openflight_mobile/ui/widgets/dispersion_canvas.dart';

/// History screen — current session live log + saved session archive.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Load saved sessions when the screen is first shown.
    context.read<SessionCubit>().loadSaved();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _TabBar(controller: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _LiveTab(),
                _SavedTab(),
              ],
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Tab bar
// ---------------------------------------------------------------------------

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: TabBar(
          controller: controller,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          tabs: const [
            Tab(text: 'THIS SESSION'),
            Tab(text: 'SAVED SESSIONS'),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Live tab — current session shots
// ---------------------------------------------------------------------------

class _LiveTab extends StatelessWidget {
  const _LiveTab();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ShotCubit, ShotState>(
        builder: (context, state) {
          if (state.history.isEmpty) return const _EmptyState(tab: 'live');
          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settings) => _LiveLayout(
              shots: state.history,
              metric: settings.metric,
            ),
          );
        },
      );
}

class _LiveLayout extends StatelessWidget {
  const _LiveLayout({required this.shots, required this.metric});

  final List<ShotDataModel> shots;
  final bool metric;

  static final _timeFmt = DateFormat('HH:mm:ss');

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
            label: 'Current Session',
            shotCount: shots.length,
            avgCarry: avgCarry,
            maxCarry: maxCarry,
            avgBallSpeed: avgBall,
            metric: metric,
            accentColor: AppColors.accent,
            trailing: BlocBuilder<SessionCubit, SessionState>(
              builder: (context, sessionState) => sessionState.activeSession ==
                      null
                  ? FilledButton.icon(
                      onPressed: () => context.read<SessionCubit>().startSession(),
                      icon: const Icon(Icons.fiber_manual_record, size: 14),
                      label: const Text('Record'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: () =>
                          context.read<SessionCubit>().endSession(),
                      icon: const Icon(Icons.stop, size: 14),
                      label: const Text('End'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.6)),
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('SHOT LOG', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          _ShotLogTable(shots: shots, metric: metric, timeFmt: _timeFmt),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved tab — persisted sessions
// ---------------------------------------------------------------------------

class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          if (state.loadingHistory) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2,
              ),
            );
          }
          if (state.errorMessage != null) {
            return _ErrorState(message: state.errorMessage!);
          }
          if (state.savedSessions.isEmpty) {
            return const _EmptyState(tab: 'saved');
          }
          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settings) => _SavedList(
              sessions: state.savedSessions,
              metric: settings.metric,
            ),
          );
        },
      );
}

class _SavedList extends StatelessWidget {
  const _SavedList({required this.sessions, required this.metric});

  final List<SessionRecord> sessions;
  final bool metric;

  static final _dateFmt = DateFormat('d MMM yyyy  HH:mm');

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: sessions.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) => _SavedSessionCard(
          session: sessions[i],
          metric: metric,
          dateFmt: _dateFmt,
          onDelete: () =>
              context.read<SessionCubit>().deleteSession(sessions[i].id),
        ),
      );
}

class _SavedSessionCard extends StatelessWidget {
  const _SavedSessionCard({
    required this.session,
    required this.metric,
    required this.dateFmt,
    required this.onDelete,
  });

  final SessionRecord session;
  final bool metric;
  final DateFormat dateFmt;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avgCarry = session.avgCarry;
    final maxCarry = session.maxCarry;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(AppRadius.md),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFmt.format(session.startDateTime),
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        '${session.shotCount} shot${session.shotCount == 1 ? '' : 's'}'
                        '${session.duration != null ? '  ·  ${_fmtDuration(session.duration!)}' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.onSurfaceMuted,
                  ),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          // Stats row
          if (avgCarry != null) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _MiniMetric(
                    label: 'AVG CARRY',
                    value: UnitConverter.carry(avgCarry, metric: metric),
                  ),
                  if (maxCarry != null)
                    _MiniMetric(
                      label: 'BEST',
                      value: UnitConverter.carry(maxCarry, metric: metric),
                    ),
                  _MiniMetric(
                    label: 'CLUBS',
                    value: '${session.clubSummaries.length}',
                  ),
                ],
              ),
            ),
          ],
          // Dispersion thumbnail
          if (session.shotCount > 1) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: DispersionCanvas(
                history: session.shots,
                targetDistanceYards: session.avgCarry ?? 150,
                interactive: false,
              ),
            ),
          ],
          // Expand button
          if (session.shotCount > 0)
            TextButton(
              onPressed: () => _showDetail(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              ),
              child: const Text('View details →'),
            ),
        ],
      ),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Delete session?'),
        content:
            const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final metric = context.read<SettingsCubit>().state.metric;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scroll) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.vertical(top: AppRadius.lg),
            border: Border(
              top: BorderSide(color: AppColors.outlineVariant),
              left: BorderSide(color: AppColors.outlineVariant),
              right: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          child: _SessionDetailSheet(
            session: session,
            metric: metric,
            scrollController: scroll,
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session detail bottom sheet
// ---------------------------------------------------------------------------

class _SessionDetailSheet extends StatelessWidget {
  const _SessionDetailSheet({
    required this.session,
    required this.metric,
    required this.scrollController,
  });

  final SessionRecord session;
  final bool metric;
  final ScrollController scrollController;

  static final _timeFmt = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaries = session.clubSummaries.values.toList()
      ..sort((a, b) => b.avgCarry.compareTo(a.avgCarry));

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Handle
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Dispersion for this session
        Text('DISPERSION', style: theme.textTheme.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        DispersionCanvas(
          history: session.shots,
          targetDistanceYards: session.avgCarry ?? 150,
        ),
        const SizedBox(height: AppSpacing.md),
        // Club breakdown table
        if (summaries.isNotEmpty) ...[
          Text('CLUB AVERAGES', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          _ClubBreakdownTable(summaries: summaries, metric: metric),
          const SizedBox(height: AppSpacing.md),
        ],
        // Shot log
        Text('SHOT LOG', style: theme.textTheme.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        _ShotLogTable(
          shots: session.shots,
          metric: metric,
          timeFmt: _timeFmt,
        ),
      ],
    );
  }
}

class _ClubBreakdownTable extends StatelessWidget {
  const _ClubBreakdownTable({
    required this.summaries,
    required this.metric,
  });

  final List<ClubSummary> summaries;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final carryUnit = UnitConverter.carryUnit(metric: metric);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.all(AppRadius.md),
        border:
            Border.fromBorderSide(BorderSide(color: AppColors.outlineVariant)),
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
                  width: 40,
                  child: Text('CLB', style: theme.textTheme.labelSmall),
                ),
                Expanded(
                  child: Text(
                    'AVG ($carryUnit)',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'MAX ($carryUnit)',
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
          ...summaries.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isLast = i == summaries.length - 1;
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
                        child: _MiniClubBadge(clubId: s.clubId),
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
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${s.count}',
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
// Shot log table (shared between live and saved)
// ---------------------------------------------------------------------------

class _ShotLogTable extends StatelessWidget {
  const _ShotLogTable({
    required this.shots,
    required this.metric,
    required this.timeFmt,
  });

  final List<ShotDataModel> shots;
  final bool metric;
  final DateFormat timeFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    carryUnit.toUpperCase(),
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    speedUnit.toUpperCase(),
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
            final time = timeFmt.format(s.dateTime.toLocal());
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
// Session summary card (shared)
// ---------------------------------------------------------------------------

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({
    required this.label,
    required this.shotCount,
    required this.avgCarry,
    required this.maxCarry,
    required this.avgBallSpeed,
    required this.metric,
    required this.accentColor,
    this.trailing,
  });

  final String label;
  final int shotCount;
  final double avgCarry;
  final double maxCarry;
  final double avgBallSpeed;
  final bool metric;
  final Color accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: const BorderRadius.all(AppRadius.md),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: const BorderSide(color: AppColors.outlineVariant, width: 1),
          right: const BorderSide(color: AppColors.outlineVariant, width: 1),
          bottom: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
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
                  value: UnitConverter.carry(avgCarry, metric: metric),
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'BEST',
                  value: UnitConverter.carry(maxCarry, metric: metric),
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'AVG BALL',
                  value: UnitConverter.speed(avgBallSpeed, metric: metric),
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
            fontSize: 13,
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

// ---------------------------------------------------------------------------
// Empty + error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab});
  final String tab;

  @override
  Widget build(BuildContext context) {
    final isLive = tab == 'live';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.sports_golf_outlined : Icons.folder_open_outlined,
            size: 48,
            color: AppColors.onSurfaceMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isLive ? 'No shots yet' : 'No saved sessions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isLive
                ? 'Hit a shot to start recording'
                : 'Start recording a session from the This Session tab',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load sessions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    context.read<SessionCubit>().loadSaved(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
