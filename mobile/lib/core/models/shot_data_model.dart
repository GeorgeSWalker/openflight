import 'package:equatable/equatable.dart';

/// App-level shot data model (decoupled from the protobuf generated type).
///
/// This acts as a clean domain model; the [LaunchMonitorClient] maps
/// the protobuf [ShotData] into this type so the rest of the app
/// has no gRPC import dependency.
class ShotDataModel extends Equatable {
  const ShotDataModel({
    required this.ballSpeedMph,
    required this.clubSpeedMph,
    required this.launchAngleV,
    required this.launchAngleH,
    required this.spinRpm,
    required this.carryYards,
    required this.clubId,
    required this.timestamp,
  });

  final double ballSpeedMph;
  final double clubSpeedMph;
  final double launchAngleV;
  final double launchAngleH;
  final int spinRpm;
  final double carryYards;
  final String clubId;

  /// Unix epoch milliseconds.
  final int timestamp;

  /// Smash factor = ball speed / club speed. Returns null when club speed is 0.
  double? get smashFactor =>
      clubSpeedMph > 0 ? ballSpeedMph / clubSpeedMph : null;

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);

  ShotDataModel copyWith({
    double? ballSpeedMph,
    double? clubSpeedMph,
    double? launchAngleV,
    double? launchAngleH,
    int? spinRpm,
    double? carryYards,
    String? clubId,
    int? timestamp,
  }) =>
      ShotDataModel(
        ballSpeedMph: ballSpeedMph ?? this.ballSpeedMph,
        clubSpeedMph: clubSpeedMph ?? this.clubSpeedMph,
        launchAngleV: launchAngleV ?? this.launchAngleV,
        launchAngleH: launchAngleH ?? this.launchAngleH,
        spinRpm: spinRpm ?? this.spinRpm,
        carryYards: carryYards ?? this.carryYards,
        clubId: clubId ?? this.clubId,
        timestamp: timestamp ?? this.timestamp,
      );

  Map<String, dynamic> toJson() => {
        'ball_speed_mph': ballSpeedMph,
        'club_speed_mph': clubSpeedMph,
        'launch_angle_v': launchAngleV,
        'launch_angle_h': launchAngleH,
        'spin_rpm': spinRpm,
        'carry_yards': carryYards,
        'club_id': clubId,
        'timestamp': timestamp,
      };

  factory ShotDataModel.fromJson(Map<String, dynamic> json) => ShotDataModel(
        ballSpeedMph: (json['ball_speed_mph'] as num).toDouble(),
        clubSpeedMph: (json['club_speed_mph'] as num).toDouble(),
        launchAngleV: (json['launch_angle_v'] as num).toDouble(),
        launchAngleH: (json['launch_angle_h'] as num).toDouble(),
        spinRpm: json['spin_rpm'] as int,
        carryYards: (json['carry_yards'] as num).toDouble(),
        clubId: json['club_id'] as String,
        timestamp: json['timestamp'] as int,
      );

  /// Mock data for UI development / demos.
  static ShotDataModel mock({
    double ballSpeedMph = 152.4,
    double clubSpeedMph = 102.1,
    double launchAngleV = 10.8,
    double launchAngleH = 1.2,
    int spinRpm = 2450,
    double carryYards = 248.0,
    String clubId = 'DR',
  }) =>
      ShotDataModel(
        ballSpeedMph: ballSpeedMph,
        clubSpeedMph: clubSpeedMph,
        launchAngleV: launchAngleV,
        launchAngleH: launchAngleH,
        spinRpm: spinRpm,
        carryYards: carryYards,
        clubId: clubId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

  @override
  List<Object?> get props => [
        ballSpeedMph,
        clubSpeedMph,
        launchAngleV,
        launchAngleH,
        spinRpm,
        carryYards,
        clubId,
        timestamp,
      ];

  @override
  String toString() =>
      'ShotDataModel(ball=${ballSpeedMph.toStringAsFixed(1)}mph, '
      'carry=${carryYards.toStringAsFixed(0)}yds, '
      'spin=$spinRpm rpm, club=$clubId)';
}

/// List of supported club identifiers in display order.
const kClubIds = <String>[
  'DR',
  '3W',
  '5W',
  '4H',
  '5H',
  '4I',
  '5I',
  '6I',
  '7I',
  '8I',
  '9I',
  'PW',
  'GW',
  'SW',
  'LW',
];

/// Human-readable label for a club id.
String clubLabel(String id) {
  const labels = <String, String>{
    'DR': 'Driver',
    '3W': '3 Wood',
    '5W': '5 Wood',
    '4H': '4 Hybrid',
    '5H': '5 Hybrid',
    '4I': '4 Iron',
    '5I': '5 Iron',
    '6I': '6 Iron',
    '7I': '7 Iron',
    '8I': '8 Iron',
    '9I': '9 Iron',
    'PW': 'Pitching Wedge',
    'GW': 'Gap Wedge',
    'SW': 'Sand Wedge',
    'LW': 'Lob Wedge',
  };
  return labels[id] ?? id;
}
