import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:openflight_mobile/core/models/shot_data_model.dart';
import 'package:openflight_mobile/core/utils/app_logger.dart';
import 'package:openflight_mobile/services/session_service.dart';

export 'package:openflight_mobile/services/session_service.dart'
    show SessionRecord;

part 'session_state.dart';

/// Manages session lifecycle (start, append shots, end, persist, load).
///
/// Auto-ends a session if no shots are added for [_kIdleTimeout] (5 minutes),
/// or when [_kMaxShots] shots have been recorded — whichever comes first.
/// This prevents test/mock sessions from accumulating indefinitely.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._service) : super(const SessionState());

  final SessionService _service;
  Timer? _idleTimer;

  static final _idFmt = DateFormat('yyyyMMdd_HHmmss');

  /// Auto-end after 5 minutes with no new shots.
  static const _kIdleTimeout = Duration(minutes: 5);

  /// Hard cap on shots per session — prevents indefinite mock accumulation.
  static const _kMaxShots = 200;

  /// Load previously saved sessions from disk.
  Future<void> loadSaved() async {
    emit(state.copyWith(loadingHistory: true));
    try {
      final saved = await _service.loadAll();
      emit(state.copyWith(savedSessions: saved, loadingHistory: false));
    } catch (e, s) {
      AppLogger.error('loadSaved failed', error: e, stackTrace: s);
      emit(state.copyWith(
        errorMessage: 'Could not load sessions',
        loadingHistory: false,
      ));
    }
  }

  /// Begin a new recording session.
  void startSession() {
    if (state.activeSession != null) return; // already recording
    final id = 'session_${_idFmt.format(DateTime.now())}';
    final session = SessionRecord(
      id: id,
      startedAt: DateTime.now().millisecondsSinceEpoch,
      shots: [],
    );
    emit(state.copyWith(activeSession: session, clearError: true));
    _restartIdleTimer();
    AppLogger.info('Session started: $id', tag: 'session');
  }

  /// Append a shot to the active session and auto-save.
  ///
  /// Auto-ends the session if [_kMaxShots] is reached, preventing unbounded
  /// growth during mock/test usage where shots stream continuously.
  Future<void> addShot(ShotDataModel shot) async {
    final active = state.activeSession;
    if (active == null) return;

    if (active.shots.length >= _kMaxShots) {
      AppLogger.warning(
        'Session reached $_kMaxShots shots — auto-ending',
        tag: 'session',
      );
      await endSession();
      return;
    }

    final updated = SessionRecord(
      id: active.id,
      startedAt: active.startedAt,
      shots: [...active.shots, shot],
    );
    emit(state.copyWith(activeSession: updated));
    _restartIdleTimer();
    // Auto-save after each shot so no data is lost on crash.
    await _service.save(updated);
  }

  /// End the active session, persist, and add to saved list.
  Future<void> endSession() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final active = state.activeSession;
    if (active == null) return;
    final finished = active.copyWith(
      endedAt: DateTime.now().millisecondsSinceEpoch,
    );
    emit(state.copyWith(
      activeSession: null,
      clearActive: true,
      savedSessions: [finished, ...state.savedSessions],
    ));
    await _service.save(finished);
    AppLogger.info(
      'Session ended: ${finished.id} (${finished.shotCount} shots)',
      tag: 'session',
    );
  }

  /// Delete a saved session.
  Future<void> deleteSession(String sessionId) async {
    await _service.delete(sessionId);
    emit(state.copyWith(
      savedSessions: state.savedSessions
          .where((s) => s.id != sessionId)
          .toList(),
    ));
  }

  bool get isRecording => state.activeSession != null;

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_kIdleTimeout, () {
      AppLogger.info(
        'Session idle for ${_kIdleTimeout.inMinutes}m — auto-ending',
        tag: 'session',
      );
      endSession();
    });
  }

  @override
  Future<void> close() {
    _idleTimer?.cancel();
    return super.close();
  }
}
