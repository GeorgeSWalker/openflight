import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:openflight_mobile/bloc/settings/settings_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/core/utils/unit_converter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Top-down 2D "targeting" view.
///
/// When [interactive] is true (default), dots are tappable and show a full
/// shot breakdown sheet. When false, the canvas is read-only — suitable for
/// compact thumbnails in session cards.
class DispersionCanvas extends StatefulWidget {
  const DispersionCanvas({
    super.key,
    required this.history,
    required this.targetDistanceYards,
    this.interactive = true,
  });

  final List<ShotDataModel> history;
  final double targetDistanceYards;

  /// Whether tap-to-select is enabled. Set to false for thumbnail previews.
  final bool interactive;

  @override
  State<DispersionCanvas> createState() => _DispersionCanvasState();
}

class _DispersionCanvasState extends State<DispersionCanvas> {
  ShotDataModel? _selectedShot;

  static const double _yardRange = 320.0;
  static const double _hSpreadYards = 30.0;
  static const double _tapRadius = 20.0; // logical pixels hit area

  Offset _dotOffset(ShotDataModel shot, Size size) => Offset(
        _hToX(shot.launchAngleH, size.width),
        size.height - (shot.carryYards / _yardRange) * size.height,
      );

  double _hToX(double angleH, double width) {
    final normalised = (angleH + _hSpreadYards) / (_hSpreadYards * 2);
    return normalised.clamp(0.0, 1.0) * width;
  }

  void _handleTap(TapUpDetails details, Size size) {
    final tapPos = details.localPosition;
    ShotDataModel? nearest;
    double nearestDist = double.infinity;

    for (final shot in widget.history) {
      final pos = _dotOffset(shot, size);
      final d = (pos - tapPos).distance;
      if (d < _tapRadius && d < nearestDist) {
        nearestDist = d;
        nearest = shot;
      }
    }

    if (nearest == null) {
      setState(() => _selectedShot = null);
      return;
    }

    setState(() => _selectedShot = nearest);

    final metric = context.read<SettingsCubit>().state.metric;
    _showShotDetail(nearest!, metric: metric);
  }

  void _showShotDetail(ShotDataModel shot, {required bool metric}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShotDetailSheet(shot: shot, metric: metric),
    ).whenComplete(() => setState(() => _selectedShot = null));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) => LayoutBuilder(
        builder: (context, constraints) {
          final painter = _DispersionPainter(
            history: widget.history,
            targetDistanceYards: widget.targetDistanceYards,
            selectedShot: _selectedShot,
            metric: settings.metric,
          );

          final canvas = ClipRRect(
            borderRadius: const BorderRadius.all(AppRadius.md),
            child: CustomPaint(
              painter: painter,
              child: const SizedBox.expand(),
            ),
          );

          // Thumbnail mode: fixed 16:9 aspect ratio, no tap detection.
          if (!widget.interactive) {
            return AspectRatio(aspectRatio: 16 / 9, child: canvas);
          }

          return AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(AppRadius.md),
              child: GestureDetector(
                onTapUp: (d) => _handleTap(d, _canvasSize(constraints)),
                child: CustomPaint(
                  painter: painter,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Returns the actual canvas size used by the inner CustomPaint.
  /// We must compute it the same way the AspectRatio widget does.
  Size _canvasSize(BoxConstraints outer) {
    final w = outer.maxWidth;
    final h = outer.maxHeight;
    const ratio = 9.0 / 16.0;
    if (w / h > ratio) {
      return Size(h * ratio, h);
    } else {
      return Size(w, w / ratio);
    }
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _DispersionPainter extends CustomPainter {
  _DispersionPainter({
    required this.history,
    required this.targetDistanceYards,
    this.selectedShot,
    this.metric = false,
  });

  final List<ShotDataModel> history;
  final double targetDistanceYards;
  final ShotDataModel? selectedShot;
  final bool metric;

  static const double _yardRange = 320.0;
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
      Paint()..color = AppColors.surfaceContainerLow,
    );
  }

  void _drawYardLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 0.5;

    const step = 50.0;
    for (var y = step; y < _yardRange; y += step) {
      final displayY = metric ? UnitConverter.yardsToMeters(y) : y;
      final dy = size.height - (y / _yardRange) * size.height;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);

      final label =
          metric ? '${displayY.toStringAsFixed(0)}m' : '${y.toInt()}y';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, dy - 11));
    }

    // Centre line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = AppColors.divider
        ..strokeWidth = 0.5,
    );
  }

  void _drawTarget(Canvas canvas, Size size) {
    final dy =
        size.height - (targetDistanceYards / _yardRange) * size.height;
    final cx = size.width / 2;

    canvas.drawCircle(
      Offset(cx, dy),
      20,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, dy),
      20,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final polePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, dy), Offset(cx, dy - 18), polePaint);

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
      final isSelected = shot == selectedShot;
      final age = i / math.max(history.length - 1, 1);

      final dx = _hToX(shot.launchAngleH, size.width);
      final dy = size.height - (shot.carryYards / _yardRange) * size.height;
      final offset = Offset(dx, dy);

      final dotColor = isSelected
          ? AppColors.secondary
          : isLatest
              ? AppColors.accent
              : AppColors.accent.withValues(alpha: 0.6 - age * 0.45);

      final radius = isSelected ? 8.0 : isLatest ? 6.0 : 4.0;

      // Shadow
      canvas.drawCircle(
        Offset(dx + 1, dy + 1),
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );

      canvas.drawCircle(offset, radius, Paint()..color = dotColor);

      if (isLatest || isSelected) {
        canvas.drawCircle(
          offset,
          radius + 6,
          Paint()
            ..color = dotColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Tap hint: small tap-target ring shown on hover in debug, invisible in prod
    }
  }

  double _hToX(double angleH, double width) {
    final normalised = (angleH + _hSpreadYards) / (_hSpreadYards * 2);
    return normalised.clamp(0.0, 1.0) * width;
  }

  @override
  bool shouldRepaint(_DispersionPainter old) =>
      old.history != history ||
      old.targetDistanceYards != targetDistanceYards ||
      old.selectedShot != selectedShot ||
      old.metric != metric;
}

// ---------------------------------------------------------------------------
// Shot detail sheet
// ---------------------------------------------------------------------------

class _ShotDetailSheet extends StatelessWidget {
  const _ShotDetailSheet({required this.shot, required this.metric});

  final ShotDataModel shot;
  final bool metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final smash = shot.smashFactor;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.all(AppRadius.lg),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Club + timestamp header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: const BorderRadius.all(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        shot.clubId,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Shot at ${_formatTime(shot.dateTime)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Primary metric row
                Row(
                  children: [
                    _MetricBlock(
                      label: 'CARRY',
                      value: UnitConverter.carryValue(
                        shot.carryYards,
                        metric: metric,
                      ),
                      unit: UnitConverter.carryUnit(metric: metric),
                      highlight: true,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MetricBlock(
                      label: 'BALL SPEED',
                      value: UnitConverter.speedValue(
                        shot.ballSpeedMph,
                        metric: metric,
                      ),
                      unit: UnitConverter.speedUnit(metric: metric),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MetricBlock(
                      label: 'CLUB SPEED',
                      value: UnitConverter.speedValue(
                        shot.clubSpeedMph,
                        metric: metric,
                      ),
                      unit: UnitConverter.speedUnit(metric: metric),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Secondary metric row
                Row(
                  children: [
                    _MetricBlock(
                      label: 'SPIN',
                      value: '${shot.spinRpm}',
                      unit: 'rpm',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MetricBlock(
                      label: 'LAUNCH V',
                      value: shot.launchAngleV.toStringAsFixed(1),
                      unit: '°',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MetricBlock(
                      label: 'SMASH',
                      value: smash?.toStringAsFixed(2) ?? '—',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final l = dt.toLocal();
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    final s = l.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    this.unit,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? unit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(AppRadius.sm),
          border: Border.all(
            color: highlight
                ? AppColors.accent.withValues(alpha: 0.25)
                : AppColors.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: highlight ? AppColors.accent : AppColors.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
