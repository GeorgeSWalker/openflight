import 'package:flutter/material.dart';

import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/ui/widgets/glass_container.dart';

/// A frosted-glass "big number" tile for displaying a single shot metric.
///
/// Pass [infoText] to show a small ⓘ button that opens an explanatory dialog.
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

  /// When true, the tile uses an accent-tinted glass background and glow.
  final bool highlighted;
  final IconData? icon;

  /// When provided, a small ⓘ button appears in the label row.
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = highlighted ? AppColors.accent : AppColors.onSurface;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      backgroundColor: highlighted
          ? AppColors.accent.withValues(alpha: 0.10)
          : Colors.white.withValues(alpha: 0.05),
      borderColor: highlighted
          ? AppColors.accent.withValues(alpha: 0.40)
          : Colors.white.withValues(alpha: 0.10),
      borderWidth: highlighted ? 1.5 : 1.0,
      boxShadow: highlighted
          ? [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabelRow(label: label, icon: icon, infoText: infoText),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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
                  padding: const EdgeInsets.only(bottom: 5),
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
            Icon(icon, size: 11, color: AppColors.onSurfaceMuted),
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

// ---------------------------------------------------------------------------
// Animated variant — cross-fades on value change
// ---------------------------------------------------------------------------

/// Wraps [StatTile] with an [AnimatedSwitcher] that cross-fades when [value]
/// changes.
class AnimatedStatTile extends StatelessWidget {
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
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: StatTile(
          key: ValueKey(value),
          label: label,
          value: value,
          unit: unit,
          highlighted: highlighted,
          icon: icon,
          infoText: infoText,
        ),
      );
}

// ---------------------------------------------------------------------------
// Empty placeholder
// ---------------------------------------------------------------------------

/// Placeholder tile shown before the first shot arrives.
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

/// A small ⓘ icon button that opens a glass dialog explaining a metric.
class InfoButton extends StatelessWidget {
  const InfoButton({
    super.key,
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => IconButton(
        iconSize: 13,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        tooltip: 'What is $title?',
        icon: Icon(
          Icons.info_outline_rounded,
          size: 13,
          color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
        ),
        onPressed: () => _showInfo(context),
      );

  void _showInfo(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          blur: 24,
          backgroundColor: Colors.black.withValues(alpha: 0.55),
          borderColor: Colors.white.withValues(alpha: 0.14),
          borderRadius: const BorderRadius.all(AppRadius.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.85),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
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
