import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/bloc/app_mode/app_mode_cubit.dart';
import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/ui/screens/dashboard_screen.dart';
import 'package:openflight_mobile/ui/screens/simulator_screen.dart';
import 'package:openflight_mobile/ui/widgets/club_picker.dart';
import 'package:openflight_mobile/ui/widgets/connection_indicator.dart';

/// Root scaffold with app bar, bottom navigation, and Club Picker.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AppModeCubit, AppMode>(
        builder: (context, mode) => Scaffold(
          appBar: const _OpenFlightAppBar(),
          body: Column(
            children: [
              const ClubPicker(),
              const SizedBox(height: AppSpacing.sm),
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
          bottomNavigationBar: _BottomNav(currentMode: mode),
        ),
      );
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _OpenFlightAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _OpenFlightAppBar();

  @override
  Widget build(BuildContext context) => AppBar(
        title: Row(
          children: [
            _logo(),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'OpenFlight',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
            ),
          ],
        ),
        actions: const [
          ConnectionIndicator(),
          SizedBox(width: AppSpacing.md),
          _SettingsButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      );

  static Widget _logo() => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.sports_golf, size: 16, color: AppColors.onAccent),
        ),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

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
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.lg),
        ),
        // Pass the cubit down so the sheet can call connect/disconnect.
        builder: (_) => BlocProvider.value(
          value: context.read<ConnectionCubit>(),
          child: const _ConnectionSettingsSheet(),
        ),
      );
}

// ---------------------------------------------------------------------------
// Connection settings bottom sheet
// ---------------------------------------------------------------------------

class _ConnectionSettingsSheet extends StatefulWidget {
  const _ConnectionSettingsSheet();

  @override
  State<_ConnectionSettingsSheet> createState() =>
      _ConnectionSettingsSheetState();
}

class _ConnectionSettingsSheetState extends State<_ConnectionSettingsSheet> {
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
              Text('Connection',
                  style: Theme.of(context).textTheme.titleLarge),
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
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Disconnect'),
                    )
                  : FilledButton(
                      onPressed: _connect,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
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
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
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

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentMode});

  final AppMode currentMode;

  @override
  Widget build(BuildContext context) => NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withOpacity(0.2),
        selectedIndex: currentMode.index,
        onDestinationSelected: (i) =>
            context.read<AppModeCubit>().switchTo(AppMode.values[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.accent),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar, color: AppColors.accent),
            label: 'Simulator',
          ),
        ],
      );
}
