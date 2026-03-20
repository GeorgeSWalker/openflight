part of 'session_cubit.dart';

class SessionState extends Equatable {
  const SessionState({
    this.activeSession,
    this.savedSessions = const [],
    this.loadingHistory = false,
    this.errorMessage,
  });

  final SessionRecord? activeSession;
  final List<SessionRecord> savedSessions;
  final bool loadingHistory;
  final String? errorMessage;

  SessionState copyWith({
    SessionRecord? activeSession,
    bool clearActive = false,
    List<SessionRecord>? savedSessions,
    bool? loadingHistory,
    String? errorMessage,
    bool clearError = false,
  }) =>
      SessionState(
        activeSession: clearActive ? null : activeSession ?? this.activeSession,
        savedSessions: savedSessions ?? this.savedSessions,
        loadingHistory: loadingHistory ?? this.loadingHistory,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        activeSession,
        savedSessions,
        loadingHistory,
        errorMessage,
      ];
}
