import 'package:flutter/material.dart';

import 'package:openflight_mobile/core/constants/theme.dart';

/// A "big number" tile for displaying a single shot metric.
///
/// Example:
/// ```dart
/// StatTile(label: 'Ball Speed', value: '152.4', unit: 'mph')
/// ```
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.highlighted = false,
    this.icon,
  });

  final String label;
  final String value;
  final String? unit;

  /// When true, the tile uses the accent colour border and value text.
  final bool highlighted;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor =
        highlighted ? AppColors.accent : AppColors.onSurface;
    final borderColor =
        highlighted ? AppColors.accent.withOpacity(0.5) : AppColors.divider;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(AppRadius.md),
        border: Border.all(color: borderColor, width: highlighted ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabelRow(label: label, icon: icon),
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
  const _LabelRow({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.onSurfaceMuted),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
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
  });

  final String label;
  final String value;
  final String? unit;
  final bool highlighted;
  final IconData? icon;

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
      ),
    );
  }
}

/// Empty/placeholder tile shown while waiting for the first shot.
class EmptyStatTile extends StatelessWidget {
  const EmptyStatTile({super.key, required this.label, this.unit, this.icon});

  final String label;
  final String? unit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => StatTile(
        label: label,
        value: '—',
        unit: unit,
        icon: icon,
      );
}
