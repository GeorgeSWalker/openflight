import 'dart:developer' as developer;

/// Structured logger using dart:developer for DevTools integration.
///
/// All log calls are no-ops in release builds when not running in a debug
/// context — no third-party dependency required.
abstract final class AppLogger {
  static const _kAppName = 'openflight';

  static void debug(String message, {String? tag}) => developer.log(
        message,
        name: tag != null ? '$_kAppName.$tag' : _kAppName,
        level: 500, // CONFIG / FINE
      );

  static void info(String message, {String? tag}) => developer.log(
        message,
        name: tag != null ? '$_kAppName.$tag' : _kAppName,
        level: 800, // INFO
      );

  static void warning(String message, {String? tag}) => developer.log(
        message,
        name: tag != null ? '$_kAppName.$tag' : _kAppName,
        level: 900, // WARNING
      );

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) =>
      developer.log(
        message,
        name: tag != null ? '$_kAppName.$tag' : _kAppName,
        level: 1000, // SEVERE
        error: error,
        stackTrace: stackTrace,
      );
}
