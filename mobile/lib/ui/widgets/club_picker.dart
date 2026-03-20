import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:openflight_mobile/bloc/club/club_cubit.dart';
import 'package:openflight_mobile/bloc/target_distance/target_distance_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';
import 'package:openflight_mobile/core/models/shot_data_model.dart';

/// Horizontal scrolling club picker with a frosted-glass background strip.
///
/// Tapping a chip calls [ClubCubit.select], which updates local state
/// immediately and fires the gRPC UpdateConfig RPC to sync with the Pi.
class ClubPicker extends StatefulWidget {
  const ClubPicker({super.key});

  @override
  State<ClubPicker> createState() => _ClubPickerState();
}

class _ClubPickerState extends State<ClubPicker> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ClubCubit, String>(
        builder: (context, selectedClub) => ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              child: SizedBox(
                height: 54,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: kClubIds.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.xs + 2),
                  itemBuilder: (context, index) {
                    final club = kClubIds[index];
                    return _ClubChip(
                      clubId: club,
                      isSelected: club == selectedClub,
                      onTap: () => _onTap(context, club),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

  void _onTap(BuildContext context, String clubId) {
    final target = context.read<TargetDistanceCubit>().state;
    context.read<ClubCubit>().select(clubId, targetDistanceYards: target);
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.all(AppRadius.xl),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.14),
              width: isSelected ? 0 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.38),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            clubId,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 13,
                  color: isSelected
                      ? AppColors.onAccent
                      : AppColors.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      );
}
