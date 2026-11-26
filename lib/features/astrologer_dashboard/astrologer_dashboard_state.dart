import 'package:equatable/equatable.dart';

import '../session/session_model.dart';
import 'astrologer_dashboard_model.dart';

class AstrologerDashboardState extends Equatable {
  const AstrologerDashboardState({
    this.account,
    this.sessions = const [],
    this.loading = true,
    this.togglingAvailability = false,
    this.respondingId,
    this.error,
  });

  final AstrologerAccount? account;
  final List<ConsultSession> sessions; // every consultation addressed to this astrologer
  final bool loading, togglingAvailability;
  final String? respondingId; // request currently being accepted/declined
  final String? error;

  /// Oldest request first, so nobody waits behind a newer one.
  List<ConsultSession> get requests =>
      sessions.where((s) => s.status == SessionStatus.waiting).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  ConsultSession? get active {
    for (final s in sessions) {
      if (s.status == SessionStatus.ongoing) return s;
    }
    return null;
  }

  List<ConsultSession> get history =>
      sessions.where((s) => s.status != SessionStatus.waiting && s.status != SessionStatus.ongoing).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  AstrologerDashboardState copyWith({
    AstrologerAccount? account,
    List<ConsultSession>? sessions,
    bool? loading,
    bool? togglingAvailability,
    String? respondingId,
    bool clearResponding = false,
    String? error,
    bool clearError = false,
  }) =>
      AstrologerDashboardState(
        account: account ?? this.account,
        sessions: sessions ?? this.sessions,
        loading: loading ?? this.loading,
        togglingAvailability: togglingAvailability ?? this.togglingAvailability,
        respondingId: clearResponding ? null : (respondingId ?? this.respondingId),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [account, sessions, loading, togglingAvailability, respondingId, error];
}
