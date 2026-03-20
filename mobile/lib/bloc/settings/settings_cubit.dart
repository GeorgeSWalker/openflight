import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openflight_mobile/core/utils/app_logger.dart';

part 'settings_state.dart';

const _kUnitsKey = 'settings_units_metric';

/// Manages user preferences that persist across app launches.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  /// Load persisted preferences. Call once on app startup.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metric = prefs.getBool(_kUnitsKey) ?? false;
      emit(state.copyWith(metric: metric));
      AppLogger.debug('Settings loaded: metric=$metric', tag: 'settings');
    } catch (e, s) {
      AppLogger.error('Failed to load settings', error: e, stackTrace: s);
    }
  }

  Future<void> setMetric({required bool value}) async {
    emit(state.copyWith(metric: value));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kUnitsKey, value);
    } catch (e, s) {
      AppLogger.error('Failed to save settings', error: e, stackTrace: s);
    }
  }
}
