import '../../app_constants.dart';

/// Editable details written to `users/{uid}`.
class ProfileForm {
  const ProfileForm({required this.name, required this.dob, required this.birthTime, required this.birthPlace});
  final String name, dob, birthTime, birthPlace;

  Map<String, dynamic> toMap() => {
        Db.name: name,
        Db.dob: dob,
        Db.birthTime: birthTime,
        Db.birthPlace: birthPlace,
      };
}
