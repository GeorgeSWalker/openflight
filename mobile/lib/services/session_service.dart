import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/core/utils/app_logger.dart';

/// A recorded session: the shots hit during a single practice period.
class SessionRecord {
  SessionRecord({
    required this.id,
    required this.startedAt,
    required this.shots,
    this.endedAt,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String,
        startedAt: json['started_at'] as int,
        endedAt: json['ended_at'] as int?,
        shots: (json['shots'] as List<dynamic>)
            .map((s) => ShotDataModel.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final int startedAt;
  final int? endedAt;
  final List<ShotDataModel> shots;

  DateTime get startDateTime =>
      DateTime.fromMillisecondsSinceEpoch(startedAt);

  Duration? get duration => endedAt != null
      ? Duration(milliseconds: endedAt! - startedAt)
      : null;

  int get shotCount => shots.length;

  double? get avgCarry => shots.isEmpty
      ? null
      : shots.map((s) => s.carryYards).reduce((a, b) => a + b) / shots.length;

  double? get maxCarry => shots.isEmpty
      ? null
      : shots.map((s) => s.carryYards).reduce((a, b) => a > b ? a : b);

  /// Groups shots by club and computes per-club averages.
  Map<String, ClubSummary> get clubSummaries {
    final groups = <String, List<ShotDataModel>>{};
    for (final shot in shots) {
      groups.putIfAbsent(shot.clubId, () => []).add(shot);
    }
    return groups.map((clubId, clubShots) {
      final n = clubShots.length;
      final avg = clubShots.map((s) => s.carryYards).reduce((a, b) => a + b) /
          n;
      final max = clubShots
          .map((s) => s.carryYards)
          .reduce((a, b) => a > b ? a : b);
      return MapEntry(clubId, ClubSummary(clubId, n, avg, max));
    });
  }

  SessionRecord copyWith({int? endedAt}) => SessionRecord(
        id: id,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        shots: shots,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'started_at': startedAt,
        'ended_at': endedAt,
        'shots': shots.map((s) => s.toJson()).toList(),
      };
}

/// Per-club statistics computed from a [SessionRecord].
class ClubSummary {
  const ClubSummary(this.clubId, this.count, this.avgCarry, this.maxCarry);
  final String clubId;
  final int count;
  final double avgCarry;
  final double maxCarry;
}

/// Persists sessions to the device's documents directory as JSON files.
class SessionService {
  static const _kDirName = 'openflight_sessions';

  Future<Directory> _sessionsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_kDirName');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  String _filename(String sessionId) => '$sessionId.json';

  /// Save (or overwrite) a session file.
  Future<void> save(SessionRecord session) async {
    try {
      final dir = await _sessionsDir();
      final file = File('${dir.path}/${_filename(session.id)}');
      await file.writeAsString(jsonEncode(session.toJson()));
      AppLogger.info(
        'Session saved: ${session.id} (${session.shotCount} shots)',
        tag: 'session',
      );
    } catch (e, s) {
      AppLogger.error('Failed to save session', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Load all saved sessions, newest first.
  Future<List<SessionRecord>> loadAll() async {
    try {
      final dir = await _sessionsDir();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));

      final sessions = <SessionRecord>[];
      for (final file in files) {
        try {
          final json =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          sessions.add(SessionRecord.fromJson(json));
        } catch (e) {
          AppLogger.warning(
            'Skipping corrupt session file: ${file.path}',
            tag: 'session',
          );
        }
      }
      AppLogger.info('Loaded ${sessions.length} sessions', tag: 'session');
      return sessions;
    } catch (e, s) {
      AppLogger.error('Failed to load sessions', error: e, stackTrace: s);
      return [];
    }
  }

  /// Delete a session by id.
  Future<void> delete(String sessionId) async {
    try {
      final dir = await _sessionsDir();
      final file = File('${dir.path}/${_filename(sessionId)}');
      if (file.existsSync()) {
        await file.delete();
        AppLogger.info('Session deleted: $sessionId', tag: 'session');
      }
    } catch (e, s) {
      AppLogger.error('Failed to delete session', error: e, stackTrace: s);
    }
  }
}
