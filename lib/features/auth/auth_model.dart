import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../app_constants.dart';

enum UserRole { user, astrologer }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.user ? AppStrings.roleUser : AppStrings.roleAstrologer;
}

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.role = UserRole.user,
    this.dob,
    this.birthTime,
    this.birthPlace,
  });

  final String id, name, phone;
  final UserRole role;
  final String? dob;
  final String? birthTime;
  final String? birthPlace;

  bool get isProfileComplete =>
      role == UserRole.astrologer ||
      name.trim().isNotEmpty &&
      (dob?.isNotEmpty ?? false) &&
      (birthTime?.isNotEmpty ?? false) &&
      (birthPlace?.isNotEmpty ?? false);

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return UserModel(
      id: doc.id,
      name: d[Db.name] as String? ?? '',
      phone: d[Db.phone] as String? ?? '',
      role: UserRole.values.firstWhere((r) => r.name == d[Db.role], orElse: () => UserRole.user),
      dob: d[Db.dob] as String?,
      birthTime: d[Db.birthTime] as String?,
      birthPlace: d[Db.birthPlace] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, role, dob, birthTime, birthPlace];
}
