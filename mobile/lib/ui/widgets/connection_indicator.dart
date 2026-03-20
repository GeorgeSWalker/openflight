import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/bloc/connection/connection_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/connection_state_model.dart';

/// Animated "heartbeat" indicator that shows gRPC connection status.
///
/// - Connected: pulsing green dot + ping ms
/// - Connecting: rotating arc
/// - Disconnected / error: red dot
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConnectionCubit, ConnectionStateModel>(
        builder: (_, state) => _IndicatorContent(state: state),
      );
}

class _IndicatorContent extends StatelessWidget {
  const _IndicatorContent({required this.state});

  final ConnectionStateModel state;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(),
          const SizedBox(width: AppSpacing.xs),
          _buildLabel(context),
        ],
      );

  Widget _buildDot() => switch (state.status) {
        ConnectionStatus.connected =>
          const _PulsingDot(color: AppColors.connected),
        ConnectionStatus.connecting => const _SpinningArc(),
        ConnectionStatus.disconnected =>
          const _StatusDot(color: AppColors.disconnected),
        ConnectionStatus.error => const _StatusDot(color: AppColors.error),
      };

  Widget _buildLabel(BuildContext context) {
    final (text, color) = switch (state.status) {
      ConnectionStatus.connected => (
          state.lastPingMs != null ? '${state.lastPingMs}ms' : 'Connected',
          AppColors.connected,
        ),
      ConnectionStatus.connecting => ('Connecting…', AppColors.connecting),
      ConnectionStatus.disconnected => ('No Signal', AppColors.disconnected),
      ConnectionStatus.error => ('Error', AppColors.error),
    };
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Primitives
// ---------------------------------------------------------------------------

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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
        builder: (_, __) =>
            Transform.scale(scale: _scale.value, child: _StatusDot(color: widget.color)),
      );
}

class _SpinningArc extends StatefulWidget {
  const _SpinningArc();

  @override
  State<_SpinningArc> createState() => _SpinningArcState();
}

class _SpinningArcState extends State<_SpinningArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          size: const Size(10, 10),
          painter: _ArcPainter(progress: _controller.value),
        ),
      );
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      progress * 2 * math.pi,
      math.pi * 1.2,
      false,
      Paint()
        ..color = AppColors.connecting
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
