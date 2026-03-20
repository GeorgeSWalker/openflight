import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:openflight_mobile/bloc/club/club_cubit.dart';
import 'package:openflight_mobile/bloc/clubs/user_clubs_cubit.dart';
import 'package:openflight_mobile/bloc/target_distance/target_distance_cubit.dart';
import 'package:openflight_mobile/core/constants/theme.dart';

/// Full-width club picker arranged in two evenly-spaced rows.
///
/// The club list is taken from [UserClubsCubit], so users can add or remove
/// clubs from the Device screen. Each chip fills an equal fraction of the
/// available width so the grid always spans edge-to-edge.
class ClubPicker extends StatelessWidget {
  const ClubPicker({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<UserClubsCubit, UserClubsState>(
        builder: (context, clubsState) =>
            BlocBuilder<ClubCubit, String>(
          builder: (context, selected) {
            final clubs = clubsState.clubs;
            final mid = (clubs.length / 2).ceil();
            final row1 = clubs.sublist(0, mid);
            final row2 = clubs.sublist(mid);

            return ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest
                        .withValues(alpha: 0.85),
                    border: const Border(
                      bottom: BorderSide(
                        color: AppColors.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ClubRow(clubs: row1, selected: selected),
                        if (row2.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _ClubRow(
                            clubs: row2,
                            selected: selected,
                            padToCount: row1.length,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({
    required this.clubs,
    required this.selected,
    this.padToCount,
  });

  final List<String> clubs;
  final String selected;

  /// If set, add phantom spacers so this row matches [padToCount] columns.
  final int? padToCount;

  @override
  Widget build(BuildContext context) {
    final phantoms = padToCount != null ? padToCount! - clubs.length : 0;
    return Row(
      children: [
        ...clubs.map(
          (clubId) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _ClubChip(
                clubId: clubId,
                isSelected: clubId == selected,
              ),
            ),
          ),
        ),
        for (var i = 0; i < phantoms; i++) const Expanded(child: SizedBox()),
      ],
    );
  }
}

class _ClubChip extends StatelessWidget {
  const _ClubChip({required this.clubId, required this.isSelected});

  final String clubId;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isWood = clubId == 'DR' || clubId.endsWith('W');
    final isHybrid = clubId.endsWith('H');
    final isWedge = clubId == 'PW' ||
        clubId == 'GW' ||
        clubId == 'SW' ||
        clubId == 'LW' ||
        clubId.endsWith('°');

    final inactiveColor = isWood
        ? AppColors.secondary.withValues(alpha: 0.65)
        : isHybrid
            ? AppColors.warning.withValues(alpha: 0.65)
            : isWedge
                ? AppColors.error.withValues(alpha: 0.65)
                : AppColors.onSurfaceMuted;

    return GestureDetector(
      onTap: () {
        final target = context.read<TargetDistanceCubit>().state;
        context.read<ClubCubit>().select(clubId, targetDistanceYards: target);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 30,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: const BorderRadius.all(AppRadius.sm),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.outlineVariant.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            clubId,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.accent : inactiveColor,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
