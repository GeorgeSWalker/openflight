import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:openflight_mobile/core/constants/theme.dart';

/// A frosted-glass container that blurs whatever is rendered behind it.
///
/// For the blur to be visible, the widget tree must contain visual content
/// (gradients, colour blobs, images) rendered behind this widget — a plain
/// solid-colour background produces no visible blur.
///
/// Example:
/// ```dart
/// GlassContainer(
///   padding: const EdgeInsets.all(16),
///   child: Text('Hello'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blur = 16.0,
    this.borderRadius,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Fill colour. Defaults to white at 6 % opacity.
  final Color? backgroundColor;

  /// Border colour. Defaults to white at 12 % opacity.
  final Color? borderColor;
  final double borderWidth;

  /// Gaussian blur radius applied to content behind this widget.
  final double blur;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? const BorderRadius.all(AppRadius.md);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.06),
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.12),
              width: borderWidth,
            ),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
