import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_model.dart';
import 'profile_model.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._auth, UserModel user)
      : super(ProfileState(
          name: user.name,
          dob: user.dob ?? '',
          birthTime: user.birthTime ?? '',
          birthPlace: user.birthPlace ?? '',
        ));

  final AuthCubit _auth;

  void setName(String v) => emit(state.copyWith(name: v));
  void setDob(String v) => emit(state.copyWith(dob: v));
  void setBirthTime(String v) => emit(state.copyWith(birthTime: v));
  void setBirthPlace(String v) => emit(state.copyWith(birthPlace: v));

  Future<void> save() async {
    if (state.saving) return;
    emit(state.copyWith(showErrors: true));
    if (!state.valid) return;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final uid = Backend.uid!;
      final ref = Backend.db.collection(Db.users).doc(uid);
      await ref.update(ProfileForm(
        name: state.name.trim(),
        dob: state.dob,
        birthTime: state.birthTime,
        birthPlace: state.birthPlace.trim(),
      ).toMap());
      _auth.updateUser(UserModel.fromDoc(await ref.get()));
      emit(state.copyWith(saving: false, saves: state.saves + 1));
    } catch (e) {
      emit(state.copyWith(saving: false, error: Backend.message(e)));
    }
  }
}
