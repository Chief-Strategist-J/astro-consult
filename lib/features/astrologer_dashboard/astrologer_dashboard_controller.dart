import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../session/session_model.dart';
import 'astrologer_dashboard_model.dart';
import 'astrologer_dashboard_state.dart';

/// Live view of the astrologer's availability and consultations (requests, active call, history).
class AstrologerDashboardCubit extends Cubit<AstrologerDashboardState> {
  AstrologerDashboardCubit() : super(const AstrologerDashboardState()) {
    _listen();
  }

  /// Layout previews / widget tests: renders [initial] without any Firebase listeners.
  @visibleForTesting
  AstrologerDashboardCubit.preview(super.initialState);

  final List<StreamSubscription> _subs = [];

  void _listen() {
    final uid = Backend.uid;
    if (uid == null) return;
    _subs.add(Backend.db.collection(Db.astrologers).doc(uid).snapshots().listen(
      (doc) => emit(state.copyWith(
        account: doc.exists ? AstrologerAccount.fromDoc(doc) : null,
        loading: false,
        clearError: true,
      )),
      onError: (Object e) => emit(state.copyWith(loading: false, error: Backend.message(e))),
    ));
    _subs.add(Backend.db.collection(Db.sessions).where(Db.astrologerId, isEqualTo: uid).snapshots().listen(
      (snap) => emit(state.copyWith(sessions: snap.docs.map(ConsultSession.fromDoc).toList(), loading: false)),
      onError: (Object e) => emit(state.copyWith(loading: false, error: Backend.message(e))),
    ));
  }

  Future<void> setOnline(bool online) async {
    if (state.togglingAvailability) return;
    emit(state.copyWith(togglingAvailability: true, clearError: true));
    try {
      await Backend.call(Fn.setAvailability, {Fn.argOnline: online});
      emit(state.copyWith(togglingAvailability: false));
    } catch (e) {
      emit(state.copyWith(togglingAvailability: false, error: Backend.message(e)));
    }
  }

  /// Returns true when the request was answered successfully.
  Future<bool> respond(ConsultSession request, {required bool accept}) async {
    if (state.respondingId != null) return false;
    emit(state.copyWith(respondingId: request.id, clearError: true));
    try {
      await Backend.call(Fn.respondToSession, {Fn.argSessionId: request.id, Fn.argAccept: accept});
      emit(state.copyWith(clearResponding: true));
      return true;
    } catch (e) {
      emit(state.copyWith(clearResponding: true, error: Backend.message(e)));
      return false;
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    for (final s in _subs) {
      s.cancel();
    }
    return super.close();
  }
}
