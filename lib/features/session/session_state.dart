import 'package:equatable/equatable.dart';

import 'session_model.dart';

enum SessionPhase { idle, starting, waiting, ongoing, completed, failed }

class SessionState extends Equatable {
  const SessionState({
    this.phase = SessionPhase.idle,
    this.session,
    this.elapsed = 0,
    this.error,
    this.reconnecting = false,
    this.ending = false,
    this.history = const [],
    this.historyLoading = false,
    this.historyError,
  });

  final SessionPhase phase;
  final ConsultSession? session;
  final int elapsed;
  final String? error;
  final bool reconnecting, ending;
  final List<ConsultSession> history;
  final bool historyLoading;
  final String? historyError;

  double get runningCost => session == null ? 0 : (elapsed / 60).ceil() * session!.pricePerMin;

  SessionState copyWith({
    SessionPhase? phase,
    ConsultSession? session,
    int? elapsed,
    String? error,
    bool clearError = false,
    bool? reconnecting,
    bool? ending,
    List<ConsultSession>? history,
    bool? historyLoading,
    String? historyError,
    bool clearHistoryError = false,
  }) =>
      SessionState(
        phase: phase ?? this.phase,
        session: session ?? this.session,
        elapsed: elapsed ?? this.elapsed,
        error: clearError ? null : (error ?? this.error),
        reconnecting: reconnecting ?? this.reconnecting,
        ending: ending ?? this.ending,
        history: history ?? this.history,
        historyLoading: historyLoading ?? this.historyLoading,
        historyError: clearHistoryError ? null : (historyError ?? this.historyError),
      );

  @override
  List<Object?> get props =>
      [phase, session, elapsed, error, reconnecting, ending, history, historyLoading, historyError];
}
