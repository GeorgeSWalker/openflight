import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';

/// Top-down 2D "targeting" view showing:
/// - A flag / target circle at [targetDistanceYards]
/// - Landing dots for each shot in [history] (older = more faded)
/// - The most recent shot highlighted in accent green
class DispersionCanvas extends StatelessWidget {
  const DispersionCanvas({
    super.key,
    required this.history,
    required this.targetDistanceYards,
  });

  final List<ShotDataModel> history;
  final double targetDistanceYards;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(AppRadius.md),
          child: CustomPaint(
            painter: _DispersionPainter(
              history: history,
              targetDistanceYards: targetDistanceYards,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}

class _DispersionPainter extends CustomPainter {
  _DispersionPainter({
    required this.history,
    required this.targetDistanceYards,
  });

  final List<ShotDataModel> history;
  final double targetDistanceYards;

  // How many yards the canvas represents vertically.
  static const double _yardRange = 320.0;

  // Horizontal spread in yards visible (±).
  static const double _hSpreadYards = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawYardLines(canvas, size);
    _drawTarget(canvas, size);
    _drawShots(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.surfaceVariant,
    );
  }

  void _drawYardLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 0.5;
    final textStyle = const TextStyle(
      color: AppColors.onSurfaceMuted,
      fontSize: 9,
    );

    const step = 50.0; // yards between grid lines
    for (var y = step; y < _yardRange; y += step) {
      final dy = size.height - (y / _yardRange) * size.height;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);

      final tp = TextPainter(
        text: TextSpan(text: '${y.toInt()}y', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, dy - 11));
    }

    // Centre line (fairway)
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = AppColors.divider
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawTarget(Canvas canvas, Size size) {
    final dy = size.height - (targetDistanceYards / _yardRange) * size.height;
    final cx = size.width / 2;

    // Outer ring
    canvas.drawCircle(
      Offset(cx, dy),
      20,
      Paint()
        ..color = AppColors.accent.withValues(alpha:0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, dy),
      20,
      Paint()
        ..color = AppColors.accent.withValues(alpha:0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Flag pole
    final polePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, dy), Offset(cx, dy - 18), polePaint);

    // Flag triangle
    final flagPath = Path()
      ..moveTo(cx, dy - 18)
      ..lineTo(cx + 10, dy - 13)
      ..lineTo(cx, dy - 8)
      ..close();
    canvas.drawPath(flagPath, Paint()..color = AppColors.accent);
  }

  void _drawShots(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    for (var i = history.length - 1; i >= 0; i--) {
      final shot = history[i];
      final isLatest = i == 0;
      final age = i / math.max(history.length - 1, 1); // 0 = newest, 1 = oldest

      final dx = _hToX(shot.launchAngleH, size.width);
      final dy = size.height - (shot.carryYards / _yardRange) * size.height;

      final color = isLatest
          ? AppColors.accent
          : AppColors.accent.withValues(alpha:0.6 - age * 0.45);

      // Shadow
      canvas.drawCircle(
        Offset(dx + 1, dy + 1),
        isLatest ? 6 : 4,
        Paint()..color = Colors.black.withValues(alpha:0.3),
      );

      canvas.drawCircle(
        Offset(dx, dy),
        isLatest ? 6 : 4,
        Paint()..color = color,
      );

      if (isLatest) {
        // Outer glow ring for the newest shot.
        canvas.drawCircle(
          Offset(dx, dy),
          12,
          Paint()
            ..color = AppColors.accent.withValues(alpha:0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  /// Maps a horizontal launch angle to an x pixel coordinate.
  double _hToX(double angleH, double width) {
    final normalised = (angleH + _hSpreadYards) / (_hSpreadYards * 2);
    return normalised.clamp(0.0, 1.0) * width;
  }

  @override
  bool shouldRepaint(_DispersionPainter old) =>
      old.history != history || old.targetDistanceYards != targetDistanceYards;
}
