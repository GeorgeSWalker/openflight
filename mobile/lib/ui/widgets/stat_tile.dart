import 'package:flutter/material.dart';

import 'package:openflight_mobile/core/constants/theme.dart';

/// A "big number" tile for displaying a single shot metric.
///
/// Pass [infoText] to show a small ⓘ button that opens an explanatory dialog.
///
/// Example:
/// ```dart
/// StatTile(
///   label: 'Carry',
///   value: '248',
///   unit: 'yds',
///   highlighted: true,
///   infoText: 'Distance the ball travels through the air.',
/// )
/// ```
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.highlighted = false,
    this.icon,
    this.infoText,
  });

  final String label;
  final String value;
  final String? unit;

  /// When true, the tile uses the accent colour border, value text, and glow.
  final bool highlighted;
  final IconData? icon;

  /// When provided, a small ⓘ button appears in the label row.
  /// Tapping it opens a dialog with this explanation text.
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = highlighted ? AppColors.accent : AppColors.onSurface;
    final borderColor = highlighted
        ? AppColors.accent.withValues(alpha: 0.5)
        : AppColors.divider;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? Color.lerp(AppColors.surface, AppColors.accent, 0.06)!
            : AppColors.surface,
        borderRadius: const BorderRadius.all(AppRadius.md),
        border: Border.all(color: borderColor, width: highlighted ? 1.5 : 1),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  blurRadius: 22,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabelRow(label: label, icon: icon, infoText: infoText),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: valueColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, this.icon, this.infoText});

  final String label;
  final IconData? icon;
  final String? infoText;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.onSurfaceMuted),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (infoText != null)
            InfoButton(title: label, text: infoText!),
        ],
      );
}

/// Animated version of [StatTile] that cross-fades when the value changes.
class AnimatedStatTile extends StatefulWidget {
  const AnimatedStatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.highlighted = false,
    this.icon,
    this.infoText,
  });

  final String label;
  final String value;
  final String? unit;
  final bool highlighted;
  final IconData? icon;
  final String? infoText;

  @override
  State<AnimatedStatTile> createState() => _AnimatedStatTileState();
}

class _AnimatedStatTileState extends State<AnimatedStatTile> {
  String _previousValue = '';

  @override
  Widget build(BuildContext context) {
    if (widget.value != _previousValue) {
      _previousValue = widget.value;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: StatTile(
        key: ValueKey(widget.value),
        label: widget.label,
        value: widget.value,
        unit: widget.unit,
        highlighted: widget.highlighted,
        icon: widget.icon,
        infoText: widget.infoText,
      ),
    );
  }
}

/// Empty/placeholder tile shown while waiting for the first shot.
class EmptyStatTile extends StatelessWidget {
  const EmptyStatTile({
    super.key,
    required this.label,
    this.unit,
    this.icon,
    this.infoText,
  });

  final String label;
  final String? unit;
  final IconData? icon;
  final String? infoText;

  @override
  Widget build(BuildContext context) => StatTile(
        label: label,
        value: '—',
        unit: unit,
        icon: icon,
        infoText: infoText,
      );
}

// ---------------------------------------------------------------------------
// Info button
// ---------------------------------------------------------------------------

/// A small ⓘ icon button that opens a dialog explaining a metric.
///
/// Designed to sit inline in stat tile labels and section headers.
class InfoButton extends StatelessWidget {
  const InfoButton({
    super.key,
    required this.title,
    required this.text,
  });

  /// Dialog heading — typically the metric name.
  final String title;

  /// Body text shown in the dialog.
  final String text;

  @override
  Widget build(BuildContext context) => IconButton(
        iconSize: 14,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        tooltip: 'What is $title?',
        icon: Icon(
          Icons.info_outline,
          size: 14,
          color: AppColors.onSurfaceMuted.withValues(alpha: 0.7),
        ),
        onPressed: () => _showInfo(context),
      );

  void _showInfo(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
