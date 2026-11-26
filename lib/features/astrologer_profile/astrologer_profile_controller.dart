import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../astrologers/astrologers_model.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_model.dart';
import 'astrologer_profile_state.dart';

class AstrologerProfileCubit extends Cubit<AstrologerProfileState> {
  AstrologerProfileCubit(this._auth, UserModel user) : super(AstrologerProfileState(name: user.name)) {
    _loadExisting(user.id);
  }

  /// Layout previews / widget tests: renders [initial] without loading from Firebase.
  @visibleForTesting
  AstrologerProfileCubit.preview(super.initialState, this._auth);

  final AuthCubit _auth;

  /// Pre-fills the form when the astrologer already has a profile.
  Future<void> _loadExisting(String uid) async {
    try {
      final doc = await Backend.db.collection(Db.astrologers).doc(uid).get();
      if (isClosed) return;
      if (!doc.exists) return emit(state.copyWith(loading: false));
      final a = Astrologer.fromDoc(doc);
      emit(state.copyWith(
        loading: false,
        name: a.name,
        avatar: a.avatar,
        expertise: a.expertise.join(AppStrings.listSeparator),
        languages: a.languages.join(AppStrings.listSeparator),
        experience: a.experience.toString(),
        price: a.pricePerMin.toStringAsFixed(a.pricePerMin % 1 == 0 ? 0 : 2),
        about: a.about,
      ));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: Backend.message(e)));
    }
  }

  void setName(String v) => emit(state.copyWith(name: v));
  void setAvatar(String v) => emit(state.copyWith(avatar: v));
  void setExpertise(String v) => emit(state.copyWith(expertise: v));
  void setLanguages(String v) => emit(state.copyWith(languages: v));
  void setExperience(String v) => emit(state.copyWith(experience: v));
  void setPrice(String v) => emit(state.copyWith(price: v));
  void setAbout(String v) => emit(state.copyWith(about: v));

  Future<void> save() async {
    if (state.saving) return;
    emit(state.copyWith(showErrors: true));
    if (!state.valid) return;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await Backend.call(Fn.saveAstrologerProfile, state.toForm().toMap());
      _auth.markAstrologerReady();
      emit(state.copyWith(saving: false, saves: state.saves + 1));
    } catch (e) {
      emit(state.copyWith(saving: false, error: Backend.message(e)));
    }
  }
}
