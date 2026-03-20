import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/providers/launch_monitor_provider.dart';

/// Horizontal scrolling club picker.
///
/// Tapping a chip calls [SelectedClubNotifier.select] which:
///   1. Updates local state immediately.
///   2. Fires the gRPC UpdateConfig RPC to sync with the Pi.
class ClubPicker extends ConsumerStatefulWidget {
  const ClubPicker({super.key});

  @override
  ConsumerState<ClubPicker> createState() => _ClubPickerState();
}

class _ClubPickerState extends ConsumerState<ClubPicker> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedClub = ref.watch(selectedClubProvider);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: kClubIds.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final club = kClubIds[index];
          return _ClubChip(
            clubId: club,
            isSelected: club == selectedClub,
            onTap: () => _onClubTap(club),
          );
        },
      ),
    );
  }

  Future<void> _onClubTap(String clubId) async {
    final target = ref.read(targetDistanceProvider);
    await ref
        .read(selectedClubProvider.notifier)
        .select(clubId, targetDistanceYards: target);
  }
}

class _ClubChip extends StatelessWidget {
  const _ClubChip({
    required this.clubId,
    required this.isSelected,
    required this.onTap,
  });

  final String clubId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: const BorderRadius.all(AppRadius.xl),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          clubId,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isSelected ? AppColors.onAccent : AppColors.onSurface,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
