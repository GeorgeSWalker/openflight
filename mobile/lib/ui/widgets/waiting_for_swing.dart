import 'package:flutter/material.dart';

import 'package:openflight_mobile/core/constants/theme.dart';

/// Full-area placeholder displayed while waiting for the first / next shot.
class WaitingForSwing extends StatefulWidget {
  const WaitingForSwing({super.key});

  @override
  State<WaitingForSwing> createState() => _WaitingForSwingState();
}

class _WaitingForSwingState extends State<WaitingForSwing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _opacity,
              builder: (_, child) =>
                  Opacity(opacity: _opacity.value, child: child),
              child: const Icon(
                Icons.sports_golf_outlined,
                size: 48,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Waiting for swing…',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
          ],
        ),
      );
}
