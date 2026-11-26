import 'package:equatable/equatable.dart';

import '../../app_constants.dart';
import 'astrologer_profile_model.dart';

class AstrologerProfileState extends Equatable {
  const AstrologerProfileState({
    this.name = '',
    this.avatar = '',
    this.expertise = '',
    this.languages = '',
    this.experience = '',
    this.price = '',
    this.about = '',
    this.loading = true,
    this.showErrors = false,
    this.saving = false,
    this.saves = 0,
    this.error,
  });

  final String name, avatar, expertise, languages, experience, price, about;
  final bool loading, showErrors, saving;
  final int saves;
  final String? error;

  int? get _experience => int.tryParse(experience.trim());
  num? get _price => num.tryParse(price.trim());

  bool get _nameOk => name.trim().length >= AppConfig.nameMinLength;
  bool get _expertiseOk => _listOk(expertise);
  bool get _languagesOk => _listOk(languages);
  bool get _experienceOk => _experience != null && _experience! >= 0 && _experience! <= AppConfig.experienceMax;
  bool get _priceOk => _price != null && _price! >= AppConfig.priceMin && _price! <= AppConfig.priceMax;
  bool get _aboutOk => about.trim().length <= AppConfig.aboutMax;
  bool get _avatarOk => avatar.trim().isEmpty || avatar.trim().startsWith(AppConfig.httpsPrefix);
  static bool _listOk(String raw) {
    final l = parseList(raw);
    return l.isNotEmpty && l.length <= AppConfig.listMax;
  }

  String? get nameError => showErrors && !_nameOk ? AppStrings.errName : null;
  String? get expertiseError => showErrors && !_expertiseOk ? AppStrings.errExpertise : null;
  String? get languagesError => showErrors && !_languagesOk ? AppStrings.errLanguages : null;
  String? get experienceError => showErrors && !_experienceOk ? AppStrings.errExperience : null;
  String? get priceError => showErrors && !_priceOk ? AppStrings.errPrice : null;
  String? get aboutError => showErrors && !_aboutOk ? AppStrings.errAbout : null;
  String? get avatarError => showErrors && !_avatarOk ? AppStrings.errAvatar : null;

  bool get valid => _nameOk && _expertiseOk && _languagesOk && _experienceOk && _priceOk && _aboutOk && _avatarOk;

  AstrologerProfileForm toForm() => AstrologerProfileForm(
        name: name.trim(),
        avatar: avatar.trim(),
        expertise: parseList(expertise),
        languages: parseList(languages),
        experience: _experience ?? 0,
        pricePerMin: _price ?? 0,
        about: about.trim(),
      );

  AstrologerProfileState copyWith({
    String? name,
    String? avatar,
    String? expertise,
    String? languages,
    String? experience,
    String? price,
    String? about,
    bool? loading,
    bool? showErrors,
    bool? saving,
    int? saves,
    String? error,
    bool clearError = false,
  }) =>
      AstrologerProfileState(
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        expertise: expertise ?? this.expertise,
        languages: languages ?? this.languages,
        experience: experience ?? this.experience,
        price: price ?? this.price,
        about: about ?? this.about,
        loading: loading ?? this.loading,
        showErrors: showErrors ?? this.showErrors,
        saving: saving ?? this.saving,
        saves: saves ?? this.saves,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [name, avatar, expertise, languages, experience, price, about, loading, showErrors, saving, saves, error];
}
