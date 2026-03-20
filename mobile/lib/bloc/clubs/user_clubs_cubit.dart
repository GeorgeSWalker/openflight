import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/core/utils/app_logger.dart';

part 'user_clubs_state.dart';

/// Manages the user's personalised club list.
///
/// Starts with [kClubIds] defaults. Mutations are immediately persisted to
/// [SharedPreferences] so the list survives app restarts.
class UserClubsCubit extends Cubit<UserClubsState> {
  UserClubsCubit()
      : super(UserClubsState(clubs: List.unmodifiable(kClubIds)));

  static const _kKey = 'user_clubs_v1';

  /// Load the persisted club list, falling back to [kClubIds] if absent.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kKey);
      if (raw != null && raw.isNotEmpty) {
        emit(UserClubsState(clubs: List.unmodifiable(raw)));
        AppLogger.info('Loaded ${raw.length} user clubs', tag: 'clubs');
      }
    } catch (e, s) {
      AppLogger.error('Failed to load user clubs', error: e, stackTrace: s);
    }
  }

  /// Append [clubId] (uppercased) if not already present.
  Future<void> addClub(String clubId) async {
    final id = clubId.trim().toUpperCase();
    if (id.isEmpty || state.clubs.contains(id)) return;
    final updated = [...state.clubs, id];
    emit(UserClubsState(clubs: List.unmodifiable(updated)));
    await _persist(updated);
    AppLogger.info('Club added: $id', tag: 'clubs');
  }

  /// Remove [clubId]. No-op if only one club remains.
  Future<void> removeClub(String clubId) async {
    if (state.clubs.length <= 1) return;
    final updated = state.clubs.where((c) => c != clubId).toList();
    emit(UserClubsState(clubs: List.unmodifiable(updated)));
    await _persist(updated);
    AppLogger.info('Club removed: $clubId', tag: 'clubs');
  }

  /// Restore the default [kClubIds] list.
  Future<void> resetToDefaults() async {
    emit(UserClubsState(clubs: List.unmodifiable(kClubIds)));
    await _persist(kClubIds);
    AppLogger.info('Clubs reset to defaults', tag: 'clubs');
  }

  Future<void> _persist(List<String> clubs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kKey, clubs);
    } catch (e, s) {
      AppLogger.error('Failed to persist user clubs', error: e, stackTrace: s);
    }
  }
}
