/// Conversion helpers for imperial ↔ metric display.
abstract final class UnitConverter {
  // Distance
  static double yardsToMeters(double yards) => yards * 0.9144;
  static double metersToYards(double m) => m / 0.9144;

  // Speed
  static double mphToKph(double mph) => mph * 1.60934;
  static double kphToMph(double kph) => kph / 1.60934;

  // Carry display
  static String carry(double yards, {required bool metric}) => metric
      ? '${yardsToMeters(yards).toStringAsFixed(0)} m'
      : '${yards.toStringAsFixed(0)} yds';

  static String carryValue(double yards, {required bool metric}) => metric
      ? yardsToMeters(yards).toStringAsFixed(0)
      : yards.toStringAsFixed(0);

  static String carryUnit({required bool metric}) => metric ? 'm' : 'yds';

  // Speed display
  static String speed(double mph, {required bool metric}) => metric
      ? '${mphToKph(mph).toStringAsFixed(1)} kph'
      : '${mph.toStringAsFixed(1)} mph';

  static String speedValue(double mph, {required bool metric}) => metric
      ? mphToKph(mph).toStringAsFixed(1)
      : mph.toStringAsFixed(1);

  static String speedUnit({required bool metric}) => metric ? 'kph' : 'mph';

  // Target slider: returns display value in current unit
  static double targetDisplay(double yards, {required bool metric}) =>
      metric ? yardsToMeters(yards) : yards;

  static double targetToYards(double displayValue, {required bool metric}) =>
      metric ? metersToYards(displayValue) : displayValue;

  static String targetUnit({required bool metric}) => metric ? 'm' : 'yds';

  static double targetMin({required bool metric}) =>
      metric ? yardsToMeters(50) : 50;

  static double targetMax({required bool metric}) =>
      metric ? yardsToMeters(300) : 300;
}
