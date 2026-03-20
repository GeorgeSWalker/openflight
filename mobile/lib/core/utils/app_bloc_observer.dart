import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_logger.dart';

/// BlocObserver that logs all state transitions and errors via [AppLogger].
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    AppLogger.debug(
      '${bloc.runtimeType}: ${change.currentState.runtimeType}'
      ' → ${change.nextState.runtimeType}',
      tag: 'bloc',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      '${bloc.runtimeType} threw an error',
      error: error,
      stackTrace: stackTrace,
      tag: 'bloc',
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    AppLogger.debug('${bloc.runtimeType} closed', tag: 'bloc');
    super.onClose(bloc);
  }
}
