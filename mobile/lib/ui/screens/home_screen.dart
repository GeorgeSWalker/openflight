import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:openflight_mobile/bloc/app_mode/app_mode_cubit.dart';
import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/connection_state_model.dart';
import 'package:openflight_mobile/ui/screens/compare_screen.dart';
import 'package:openflight_mobile/ui/screens/dashboard_screen.dart';
import 'package:openflight_mobile/ui/screens/device_screen.dart';
import 'package:openflight_mobile/ui/screens/history_screen.dart';
import 'package:openflight_mobile/ui/screens/simulator_screen.dart';
import 'package:openflight_mobile/ui/widgets/club_picker.dart';

/// Root scaffold — flat dark chrome with 5-tab navigation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AppModeCubit, AppMode>(
        builder: (context, mode) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: const _OpenFlightAppBar(),
          body: Column(
            children: [
              // Club picker only shown on dashboard + simulator tabs
              if (mode == AppMode.dashboard || mode == AppMode.simulator)
                const ClubPicker(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (mode) {
                    AppMode.dashboard => const DashboardScreen(),
                    AppMode.simulator => const SimulatorScreen(),
                    AppMode.compare => const CompareScreen(),
                    AppMode.history => const HistoryScreen(),
                    AppMode.device => const DeviceScreen(),
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: _GlassBottomNav(currentMode: mode),
        ),
      );
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _OpenFlightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _OpenFlightAppBar();

  @override
  Widget build(BuildContext context) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
              border: const Border(
                bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  _AppLogo(),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'OPENFLIGHT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              actions: const [
                _ConnectionPill(),
                SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
        ),
      );

  static Widget _AppLogo() => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accent.withValues(alpha: 0.15),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.40),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.sensors,
            size: 14,
            color: AppColors.accent,
          ),
        ),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ---------------------------------------------------------------------------
// Connection pill
// ---------------------------------------------------------------------------

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConnectionCubit, ConnectionStateModel>(
        builder: (_, state) {
          final (label, color) = switch (state.status) {
            ConnectionStatus.connected => (
                state.lastPingMs != null
                    ? '${state.lastPingMs}ms'
                    : 'Connected',
                AppColors.accent,
              ),
            ConnectionStatus.connecting => ('Connecting', AppColors.warning),
            ConnectionStatus.disconnected => ('No Signal', AppColors.error),
            ConnectionStatus.error => ('Error', AppColors.error),
          };

          return GestureDetector(
            onTap: () => _showConnectionSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulseDot(color: color),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  static void _showConnectionSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: AppRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: AppRadius.lg),
                border: const Border(
                  top: BorderSide(color: AppColors.outlineVariant),
                  left: BorderSide(color: AppColors.outlineVariant),
                  right: BorderSide(color: AppColors.outlineVariant),
                ),
              ),
              child: BlocProvider.value(
                value: context.read<ConnectionCubit>(),
                child: const _ConnectionSettingsSheet(),
              ),
            ),
          ),
        ),
      );
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Connection settings sheet
// ---------------------------------------------------------------------------

class _ConnectionSettingsSheet extends StatefulWidget {
  const _ConnectionSettingsSheet();

  @override
  State<_ConnectionSettingsSheet> createState() =>
      _ConnectionSettingsSheetState();
}

class _ConnectionSettingsSheetState
    extends State<_ConnectionSettingsSheet> {
  final _hostController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '50051');

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConnectionCubit, ConnectionStateModel>(
        builder: (context, state) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
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
              Text(
                'Connection',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _hostController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: const InputDecoration(labelText: 'Raspberry Pi IP'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _portController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: const InputDecoration(labelText: 'gRPC Port'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.lg),
              state.isConnected
                  ? OutlinedButton(
                      onPressed: _disconnect,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                      child: const Text('Disconnect'),
                    )
                  : FilledButton(
                      onPressed: _connect,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                      child: const Text('Connect'),
                    ),
            ],
          ),
        ),
      );

  Future<void> _connect() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 50051;
    if (host.isEmpty) return;
    await context.read<ConnectionCubit>().connect(host: host, port: port);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _disconnect() async {
    await context.read<ConnectionCubit>().disconnect();
    if (mounted) Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar — glass blur retained
// ---------------------------------------------------------------------------

class _GlassBottomNav extends StatelessWidget {
  const _GlassBottomNav({required this.currentMode});

  final AppMode currentMode;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.90),
              border: const Border(
                top: BorderSide(color: AppColors.outlineVariant, width: 1),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              selectedIndex: currentMode.index,
              onDestinationSelected: (i) =>
                  context.read<AppModeCubit>().switchTo(AppMode.values[i]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(
                    Icons.dashboard_rounded,
                    color: AppColors.accent,
                  ),
                  label: 'Dash',
                ),
                NavigationDestination(
                  icon: Icon(Icons.view_in_ar_outlined),
                  selectedIcon: Icon(
                    Icons.view_in_ar,
                    color: AppColors.accent,
                  ),
                  label: 'Range',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.accent,
                  ),
                  label: 'Compare',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(
                    Icons.history_rounded,
                    color: AppColors.accent,
                  ),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sensors_outlined),
                  selectedIcon: Icon(
                    Icons.sensors,
                    color: AppColors.accent,
                  ),
                  label: 'Device',
                ),
              ],
            ),
          ),
        ),
      );
}
