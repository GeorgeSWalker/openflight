import 'package:flutter/material.dart';

import 'package:openflight_mobile/core/constants/theme.dart';

/// Full-area placeholder displayed while waiting for the first / next shot.
///
/// Shows a pulsing ring around a golf icon with instructional copy.
class WaitingForSwing extends StatefulWidget {
  const WaitingForSwing({super.key});

  @override
  State<WaitingForSwing> createState() => _WaitingForSwingState();
}

class _WaitingForSwingState extends State<WaitingForSwing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fade = Tween<double>(begin: 0.45, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer expanding ring that fades as it grows
                  Opacity(
                    opacity:
                        (0.18 * (1.0 - _pulse.value)).clamp(0.0, 1.0),
                    child: Container(
                      width: 96 + (_pulse.value * 22),
                      height: 96 + (_pulse.value * 22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Inner circle with icon
                  Opacity(
                    opacity: _fade.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_golf_outlined,
                        size: 36,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Ready to Track',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Hit a shot to see your metrics',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
