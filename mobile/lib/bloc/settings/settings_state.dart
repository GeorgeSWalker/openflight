part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({this.metric = false});

  /// True = metric units (metres, kph). False = imperial (yards, mph).
  final bool metric;

  SettingsState copyWith({bool? metric}) =>
      SettingsState(metric: metric ?? this.metric);

  @override
  List<Object> get props => [metric];
}
