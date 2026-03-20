import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/bloc/settings/settings_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/connection_state_model.dart';

/// Device & settings screen.
///
/// Shows live connection status, connection form, unit preferences,
/// and hardware info.
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConnectionCubit, ConnectionStateModel>(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(state: state),
              const SizedBox(height: AppSpacing.md),
              const _ConnectionForm(),
              const SizedBox(height: AppSpacing.md),
              const _PreferencesCard(),
              const SizedBox(height: AppSpacing.md),
              _DeviceInfoCard(state: state),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Status card
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final ConnectionStateModel state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusLabel, statusColor) = switch (state.status) {
      ConnectionStatus.connected => ('Connected', AppColors.accent),
      ConnectionStatus.connecting => ('Connecting…', AppColors.warning),
      ConnectionStatus.disconnected => ('Disconnected', AppColors.error),
      ConnectionStatus.error => ('Error', AppColors.error),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: const BorderRadius.all(AppRadius.md),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
          top: const BorderSide(color: AppColors.outlineVariant, width: 1),
          right: const BorderSide(color: AppColors.outlineVariant, width: 1),
          bottom: const BorderSide(color: AppColors.outlineVariant, width: 1),
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
                Icons.sensors_outlined,
                size: 96,
                color: AppColors.onSurface.withValues(alpha: 0.04),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEVICE STATUS', style: theme.textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _GlowDot(color: statusColor),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        statusLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  if (state.isConnected && state.lastPingMs != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ping: ${state.lastPingMs}ms',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (state.lastError != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 13,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            state.lastError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Connection form
// ---------------------------------------------------------------------------

class _ConnectionForm extends StatefulWidget {
  const _ConnectionForm();

  @override
  State<_ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<_ConnectionForm> {
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
        builder: (context, state) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.all(AppRadius.md),
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CONNECTION',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _hostController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Raspberry Pi IP Address',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !state.isConnected,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _portController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration:
                    const InputDecoration(labelText: 'gRPC Port'),
                keyboardType: TextInputType.number,
                enabled: !state.isConnected,
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.isConnected)
                OutlinedButton.icon(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: state.status == ConnectionStatus.connecting
                      ? null
                      : _connect,
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(
                    state.status == ConnectionStatus.connecting
                        ? 'Connecting…'
                        : 'Connect',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
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
  }

  Future<void> _disconnect() async =>
      context.read<ConnectionCubit>().disconnect();
}

// ---------------------------------------------------------------------------
// Preferences card — units toggle
// ---------------------------------------------------------------------------

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREFERENCES', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.md),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settings) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Units',
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        settings.metric
                            ? 'Metric — metres, kph'
                            : 'Imperial — yards, mph',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _UnitsToggle(metric: settings.metric),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitsToggle extends StatelessWidget {
  const _UnitsToggle({required this.metric});
  final bool metric;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: const BorderRadius.all(AppRadius.sm),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.outlineVariant),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleButton(
              label: 'yds',
              selected: !metric,
              onTap: () => context
                  .read<SettingsCubit>()
                  .setMetric(value: false),
            ),
            _ToggleButton(
              label: 'm',
              selected: metric,
              onTap: () => context
                  .read<SettingsCubit>()
                  .setMetric(value: true),
            ),
          ],
        ),
      );
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
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
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: const BorderRadius.all(AppRadius.sm),
          ),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.onAccent : AppColors.onSurfaceMuted,
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Device info card
// ---------------------------------------------------------------------------

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({required this.state});

  final ConnectionStateModel state;

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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ABOUT', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.md),
          const _InfoRow(label: 'Sensor', value: 'OPS243-A Doppler Radar'),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          const _InfoRow(label: 'Protocol', value: 'gRPC / Protobuf'),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          const _InfoRow(label: 'App Version', value: '1.0.0'),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          const _InfoRow(
            label: 'Detection',
            value: 'FFT + 2D CFAR (SNR > 15 dB)',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
        ),
      ],
    );
  }
}
