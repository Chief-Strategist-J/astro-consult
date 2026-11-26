import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../astrologers/astrologers_model.dart';
import '../auth/auth_controller.dart';
import 'astrologer_detail_model.dart';
import 'astrologer_detail_state.dart';

class AstrologerDetailCubit extends Cubit<AstrologerDetailState> {
  AstrologerDetailCubit(Astrologer initial) : super(AstrologerDetailState(astrologer: initial)) {
    _watchProfile();
    load();
  }

  /// Layout previews / widget tests: renders [initial] without any Firebase listeners.
  @visibleForTesting
  AstrologerDetailCubit.preview(super.initialState);

  StreamSubscription? _sub;

  void _watchProfile() {
    _sub = Backend.db.collection(Db.astrologers).doc(state.astrologer.id).snapshots().listen((doc) {
      if (doc.exists) emit(state.copyWith(astrologer: Astrologer.fromDoc(doc)));
    }, onError: (_) {});
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final snap = await Backend.db
          .collection(Db.astrologers)
          .doc(state.astrologer.id)
          .collection(Db.reviews)
          .get();
      emit(state.copyWith(reviews: snap.docs.map(Review.fromDoc).toList(), loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: Backend.message(e)));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
