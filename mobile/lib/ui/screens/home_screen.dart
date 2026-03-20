import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/providers/launch_monitor_provider.dart';
import 'package:openflight_mobile/ui/screens/dashboard_screen.dart';
import 'package:openflight_mobile/ui/screens/simulator_screen.dart';
import 'package:openflight_mobile/ui/widgets/club_picker.dart';
import 'package:openflight_mobile/ui/widgets/connection_indicator.dart';

/// Root scaffold with app bar, bottom navigation, and Club Picker.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);

    return Scaffold(
      appBar: _OpenFlightAppBar(),
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
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _OpenFlightAppBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Row(
        children: [
          const _OpenFlightLogo(),
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
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _OpenFlightLogo extends StatelessWidget {
  const _OpenFlightLogo();

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.sports_golf,
            size: 16,
            color: AppColors.onAccent,
          ),
        ),
      );
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
        builder: (_) => const _ConnectionSettingsSheet(),
      );
}

// ---------------------------------------------------------------------------
// Connection settings bottom sheet
// ---------------------------------------------------------------------------

class _ConnectionSettingsSheet extends ConsumerStatefulWidget {
  const _ConnectionSettingsSheet();

  @override
  ConsumerState<_ConnectionSettingsSheet> createState() =>
      _ConnectionSettingsSheetState();
}

class _ConnectionSettingsSheetState
    extends ConsumerState<_ConnectionSettingsSheet> {
  final _hostController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '50051');

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(connectionStateProvider);
    final isConnected = stateAsync.valueOrNull?.isConnected ?? false;

    return Padding(
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
          Text(
            'Connection',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _hostController,
            style: const TextStyle(color: AppColors.onSurface),
            decoration: _inputDecoration('Raspberry Pi IP'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _portController,
            style: const TextStyle(color: AppColors.onSurface),
            decoration: _inputDecoration('gRPC Port'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (isConnected)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _disconnect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Disconnect'),
                  ),
                )
              else
                Expanded(
                  child: FilledButton(
                    onPressed: _connect,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                    ),
                    child: const Text('Connect'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

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
    final client = ref.read(launchMonitorClientProvider);
    await client.connect(host: host, port: port);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _disconnect() async {
    final client = ref.read(launchMonitorClientProvider);
    await client.disconnect();
    if (mounted) Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------

class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.currentMode});

  final AppMode currentMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) => NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withOpacity(0.2),
        selectedIndex: currentMode.index,
        onDestinationSelected: (i) => ref
            .read(appModeProvider.notifier)
            .switchTo(AppMode.values[i]),
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
