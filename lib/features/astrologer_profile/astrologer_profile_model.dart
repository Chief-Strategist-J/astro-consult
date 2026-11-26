import '../../app_constants.dart';

/// Splits "a, b ,c" into trimmed, non-empty items.
List<String> parseList(String raw) =>
    raw.split(AppConfig.listInputSeparator).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

/// Payload for the `saveAstrologerProfile` Cloud Function.
class AstrologerProfileForm {
  const AstrologerProfileForm({
    required this.name,
    required this.avatar,
    required this.expertise,
    required this.languages,
    required this.experience,
    required this.pricePerMin,
    required this.about,
  });

  final String name, avatar, about;
  final List<String> expertise, languages;
  final int experience;
  final num pricePerMin;

  Map<String, dynamic> toMap() => {
        Fn.argName: name,
        Fn.argAvatar: avatar,
        Fn.argExpertise: expertise,
        Fn.argLanguages: languages,
        Fn.argExperience: experience,
        Fn.argPricePerMin: pricePerMin,
        Fn.argAbout: about,
      };
}
