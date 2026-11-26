import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../astrologers/astrologers_model.dart';
import '../auth/auth_controller.dart';
import 'session_model.dart';
import 'session_state.dart';

class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(const SessionState());

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _ticker, _waitTimeout;
  DateTime? _ongoingSince;
  bool _serverClock = false; // resumed sessions count from the server's startedAt

  Future<void> start(Astrologer astrologer, ConsultType type) async {
    if (state.phase == SessionPhase.starting ||
        state.phase == SessionPhase.waiting ||
        state.phase == SessionPhase.ongoing) {
      return;
    }
    _teardown();
    _serverClock = false;
    emit(const SessionState(phase: SessionPhase.starting).copyWith(history: state.history));
    try {
      final res = await Backend.call(Fn.startSession, {
        Fn.argAstrologerId: astrologer.id,
        Fn.argType: type.name,
      });
      final id = res[Fn.resId] as String;
      emit(state.copyWith(phase: SessionPhase.waiting));
      _waitTimeout = Timer(AppConfig.acceptTimeout, _onAcceptTimeout);
      _listen(id);
    } catch (e) {
      emit(state.copyWith(phase: SessionPhase.failed, error: Backend.message(e)));
    }
  }

  /// Astrologer side: join a consultation that was just accepted (or resume one that is still ongoing).
  void attach(ConsultSession session) {
    _teardown();
    _serverClock = true;
    emit(const SessionState(phase: SessionPhase.waiting).copyWith(session: session, history: state.history));
    _listen(session.id);
  }

  void _listen(String sessionId) {
    _sub = Backend.db.collection(Db.sessions).doc(sessionId).snapshots().listen(
      (doc) {
        if (!doc.exists) {
          return _fail(AppStrings.errSessionMissing);
        }
        final active = state.phase == SessionPhase.waiting || state.phase == SessionPhase.ongoing;
        emit(state.copyWith(reconnecting: active && doc.metadata.isFromCache));
        _onStatus(ConsultSession.fromDoc(doc));
      },
      onError: (Object e) => emit(state.copyWith(reconnecting: false, error: AppStrings.errConnectionLost)),
    );
  }

  void _onStatus(ConsultSession s) {
    switch (s.status) {
      case SessionStatus.ongoing:
        if (state.phase == SessionPhase.ongoing) return emit(state.copyWith(session: s));
        _waitTimeout?.cancel();
        _ongoingSince = _serverClock ? (s.startedAt ?? DateTime.now()) : DateTime.now();
        final already = DateTime.now().difference(_ongoingSince!).inSeconds;
        _ticker?.cancel();
        _ticker = Timer.periodic(AppConfig.tick, (_) {
          emit(state.copyWith(elapsed: DateTime.now().difference(_ongoingSince!).inSeconds));
        });
        emit(state.copyWith(phase: SessionPhase.ongoing, session: s, elapsed: already < 0 ? 0 : already, clearError: true));
      case SessionStatus.completed:
        _finish(s);
      case SessionStatus.cancelled:
        if (state.ending) return;
        _finish(s, failedMessage: AppStrings.errCancelled);
      case SessionStatus.rejected:
        _finish(s, failedMessage: AppStrings.errDeclined(s.astrologerName));
      case SessionStatus.waiting:
        emit(state.copyWith(session: s));
    }
  }

  void _fail(String message) {
    _stopTimers();
    _closeStream();
    emit(state.copyWith(phase: SessionPhase.failed, error: message, ending: false, reconnecting: false));
  }

  void _finish(ConsultSession s, {String? failedMessage}) {
    if (state.phase == SessionPhase.completed || state.phase == SessionPhase.failed) return;
    _stopTimers();
    _closeStream();
    emit(state.copyWith(
      phase: failedMessage == null ? SessionPhase.completed : SessionPhase.failed,
      session: s,
      error: failedMessage,
      ending: false,
      reconnecting: false,
    ));
  }

  Future<void> _onAcceptTimeout() async {
    if (state.phase != SessionPhase.waiting) return;
    await end(silent: true);
    emit(state.copyWith(phase: SessionPhase.failed, error: AppStrings.errNoResponse));
  }

  Future<void> end({bool silent = false}) async {
    final s = state.session;
    if (s == null || state.ending) return;
    emit(state.copyWith(ending: true, clearError: true));
    try {
      final res = await Backend.call(Fn.endSession, {Fn.argSessionId: s.id});
      final done = ConsultSession.fromMap(s.id, {...res, Db.createdAt: Timestamp.fromDate(s.createdAt)});
      if (silent) {
        _stopTimers();
        _closeStream();
        emit(state.copyWith(ending: false, session: done));
      } else if (done.status == SessionStatus.cancelled) {
        _stopTimers();
        _closeStream();
        emit(state.copyWith(phase: SessionPhase.idle, ending: false));
      } else {
        _finish(done);
      }
    } catch (e) {
      emit(state.copyWith(ending: false, error: AppStrings.endFailed(Backend.message(e))));
    }
  }

  Future<void> reset() async {
    _teardown();
    emit(const SessionState().copyWith(history: state.history));
    await loadHistory();
  }

  Future<void> loadHistory() async {
    final uid = Backend.uid;
    if (uid == null) return;
    emit(state.copyWith(historyLoading: true, clearHistoryError: true));
    try {
      final snap = await Backend.db.collection(Db.sessions).where(Db.userId, isEqualTo: uid).get();
      final list = snap.docs
          .map(ConsultSession.fromDoc)
          .where((s) => s.status != SessionStatus.waiting && s.status != SessionStatus.ongoing)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(state.copyWith(history: list, historyLoading: false));
    } catch (e) {
      emit(state.copyWith(historyLoading: false, historyError: Backend.message(e)));
    }
  }

  void clearHistory() => emit(state.copyWith(history: const []));

  void _stopTimers() {
    _ticker?.cancel();
    _waitTimeout?.cancel();
  }

  void _closeStream() {
    _sub?.cancel();
    _sub = null;
  }

  void _teardown() {
    _stopTimers();
    _closeStream();
  }

  @override
  Future<void> close() {
    _teardown();
    return super.close();
  }
}
