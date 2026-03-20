import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/bloc/app_mode/app_mode_cubit.dart';
import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/ui/screens/dashboard_screen.dart';
import 'package:openflight_mobile/ui/screens/simulator_screen.dart';
import 'package:openflight_mobile/ui/widgets/club_picker.dart';
import 'package:openflight_mobile/ui/widgets/connection_indicator.dart';
import 'package:openflight_mobile/ui/widgets/glass_container.dart';

/// Root scaffold with gradient background, glassmorphism chrome, bottom nav,
/// and Club Picker.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AppModeCubit, AppMode>(
        builder: (context, mode) => Container(
          // Rich gradient that the glass layers blur against
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1020), Color(0xFF070A12)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Decorative colour blobs — give BackdropFilter something to blur
              const _BackgroundBlobs(),
              // Transparent scaffold sits on top of the gradient
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: const _OpenFlightAppBar(),
                body: Column(
                  children: [
                    const ClubPicker(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: switch (mode) {
                          AppMode.dashboard => const DashboardScreen(),
                          AppMode.simulator => const SimulatorScreen(),
                        },
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: _GlassBottomNav(currentMode: mode),
              ),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Background decoration
// ---------------------------------------------------------------------------

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Top-left green glow
            Positioned(
              top: -90,
              left: -70,
              child: _Blob(
                size: 420,
                color: AppColors.accent.withValues(alpha: 0.055),
              ),
            ),
            // Bottom-right cyan glow
            Positioned(
              bottom: -130,
              right: -90,
              child: _Blob(
                size: 460,
                color: const Color(0xFF00B4D8).withValues(alpha: 0.038),
              ),
            ),
          ],
        ),
      );
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            radius: 0.65,
          ),
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
              color: Colors.white.withValues(alpha: 0.04),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
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
                    'OpenFlight',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              actions: const [
                ConnectionIndicator(),
                SizedBox(width: AppSpacing.md),
                _SettingsButton(),
                SizedBox(width: AppSpacing.sm),
              ],
            ),
          ),
        ),
      );

  static Widget _AppLogo() => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF34D399), AppColors.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.40),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.sports_golf, size: 16, color: AppColors.onAccent),
        ),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ---------------------------------------------------------------------------
// Settings button + connection sheet
// ---------------------------------------------------------------------------

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.settings_outlined),
        tooltip: 'Connection settings',
        onPressed: () => _showConnectionSheet(context),
      );

  static void _showConnectionSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: AppRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.68),
                borderRadius:
                    const BorderRadius.vertical(top: AppRadius.lg),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
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
  final _hostController =
      TextEditingController(text: '192.168.1.100');
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
              // Sheet handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
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
                decoration: _inputDecoration('Raspberry Pi IP'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _portController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: _inputDecoration('gRPC Port'),
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

  static InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: const BorderRadius.all(AppRadius.sm),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
          borderRadius: BorderRadius.all(AppRadius.sm),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
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
// Bottom navigation bar
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
              color: Colors.black.withValues(alpha: 0.35),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              selectedIndex: currentMode.index,
              onDestinationSelected: (i) =>
                  context
                      .read<AppModeCubit>()
                      .switchTo(AppMode.values[i]),
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    Icons.dashboard_outlined,
                    color: AppColors.onSurfaceMuted,
                  ),
                  selectedIcon: const Icon(
                    Icons.dashboard_rounded,
                    color: AppColors.accent,
                  ),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.view_in_ar_outlined,
                    color: AppColors.onSurfaceMuted,
                  ),
                  selectedIcon: const Icon(
                    Icons.view_in_ar,
                    color: AppColors.accent,
                  ),
                  label: 'Simulator',
                ),
              ],
            ),
          ),
        ),
      );
}
