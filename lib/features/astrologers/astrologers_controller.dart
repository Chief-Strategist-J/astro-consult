import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import 'astrologers_model.dart';
import 'astrologers_state.dart';

class AstrologersCubit extends Cubit<AstrologersState> {
  AstrologersCubit() : super(const AstrologersState());

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  Future<void> load() async {
    await _sub?.cancel();
    emit(state.copyWith(loading: true, clearError: true));
    _sub = Backend.db.collection(Db.astrologers).snapshots().listen(
      (snap) => emit(state.copyWith(
        items: snap.docs.map(Astrologer.fromDoc).toList(),
        loading: false,
      )),
      onError: (Object e) => emit(state.copyWith(loading: false, error: Backend.message(e))),
    );
  }

  void setQuery(String q) => emit(state.copyWith(query: q));
  void setExpertise(String? e) =>
      emit(e == null ? state.copyWith(clearExpertise: true) : state.copyWith(expertise: e));
  void setOnlyOnline(bool v) => emit(state.copyWith(onlyOnline: v));
  void setSort(AstrologerSort s) => emit(state.copyWith(sort: s));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
