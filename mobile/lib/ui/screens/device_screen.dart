import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/connection_state_model.dart';

/// Device / connection settings screen.
///
/// Lets the user configure the Raspberry Pi host and gRPC port, shows
/// live connection status, and provides connect / disconnect actions.
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
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
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
                    Text(
                      state.lastError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
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
                decoration:
                    const InputDecoration(labelText: 'Raspberry Pi IP Address'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !state.isConnected,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _portController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: const InputDecoration(labelText: 'gRPC Port'),
                keyboardType: TextInputType.number,
                enabled: !state.isConnected,
              ),
              const SizedBox(height: AppSpacing.md),
              state.isConnected
                  ? OutlinedButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.link_off, size: 18),
                      label: const Text('Disconnect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.6),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                    )
                  : FilledButton.icon(
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
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
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

  Future<void> _disconnect() async {
    await context.read<ConnectionCubit>().disconnect();
  }
}

// ---------------------------------------------------------------------------
// Device info card — system info
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
          _InfoRow(label: 'Sensor', value: 'OPS243-A Doppler Radar'),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _InfoRow(label: 'Protocol', value: 'gRPC / Protobuf'),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _InfoRow(label: 'App Version', value: '1.0.0'),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          _InfoRow(
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
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
