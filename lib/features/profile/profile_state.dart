import 'package:equatable/equatable.dart';

import '../../app_constants.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.name = '',
    this.dob = '',
    this.birthTime = '',
    this.birthPlace = '',
    this.showErrors = false,
    this.saving = false,
    this.saves = 0,
    this.error,
  });

  final String name, dob, birthTime, birthPlace;
  final bool showErrors, saving;
  final int saves; // increments on each successful save so the UI can react once
  final String? error;

  String? get nameError =>
      showErrors && name.trim().length < AppConfig.nameMinLength ? AppStrings.errName : null;
  String? get dobError => showErrors && dob.isEmpty ? AppStrings.errDob : null;
  String? get timeError => showErrors && birthTime.isEmpty ? AppStrings.errBirthTime : null;
  String? get placeError => showErrors && birthPlace.trim().isEmpty ? AppStrings.errBirthPlace : null;
  bool get valid => nameError == null && dob.isNotEmpty && birthTime.isNotEmpty && birthPlace.trim().isNotEmpty && name.trim().length >= AppConfig.nameMinLength;

  ProfileState copyWith({
    String? name,
    String? dob,
    String? birthTime,
    String? birthPlace,
    bool? showErrors,
    bool? saving,
    int? saves,
    String? error,
    bool clearError = false,
  }) =>
      ProfileState(
        name: name ?? this.name,
        dob: dob ?? this.dob,
        birthTime: birthTime ?? this.birthTime,
        birthPlace: birthPlace ?? this.birthPlace,
        showErrors: showErrors ?? this.showErrors,
        saving: saving ?? this.saving,
        saves: saves ?? this.saves,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [name, dob, birthTime, birthPlace, showErrors, saving, saves, error];
}
