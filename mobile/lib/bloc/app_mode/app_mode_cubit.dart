import 'package:flutter_bloc/flutter_bloc.dart';

enum AppMode { dashboard, simulator }

/// Controls which primary screen is visible.
class AppModeCubit extends Cubit<AppMode> {
  AppModeCubit() : super(AppMode.dashboard);

  void switchTo(AppMode mode) => emit(mode);
}
