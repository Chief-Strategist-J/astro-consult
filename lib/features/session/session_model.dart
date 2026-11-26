import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../app_constants.dart';

enum ConsultType { chat, voice, video }

extension ConsultTypeInfo on ConsultType {
  String get label => switch (this) {
        ConsultType.chat => AppStrings.typeChat,
        ConsultType.voice => AppStrings.typeVoice,
        ConsultType.video => AppStrings.typeVideo,
      };
}

enum SessionStatus { waiting, ongoing, completed, cancelled, rejected }

class ConsultSession extends Equatable {
  const ConsultSession({
    required this.id,
    this.userId = '',
    this.userName = '',
    this.userDob,
    this.userBirthTime,
    this.userBirthPlace,
    this.startedAt,
    required this.astrologerId,
    required this.astrologerName,
    required this.astrologerAvatar,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.durationSec,
    required this.cost,
    required this.pricePerMin,
  });

  final String id, userId, userName, astrologerId, astrologerName, astrologerAvatar;
  final String? userDob, userBirthTime, userBirthPlace;
  final DateTime? startedAt;
  final ConsultType type;
  final SessionStatus status;
  final DateTime createdAt;
  final int durationSec;
  final double cost, pricePerMin;

  bool isAstrologer(String? uid) => uid == astrologerId;
  String counterpartName(String? uid) => isAstrologer(uid) ? userName : astrologerName;
  String counterpartAvatar(String? uid) => isAstrologer(uid) ? '' : astrologerAvatar;

  factory ConsultSession.fromMap(String id, Map<String, dynamic> j) => ConsultSession(
        id: id,
        userId: j[Db.userId] as String? ?? '',
        userName: j[Db.userName] as String? ?? '',
        userDob: j[Db.userDob] as String?,
        userBirthTime: j[Db.userBirthTime] as String?,
        userBirthPlace: j[Db.userBirthPlace] as String?,
        startedAt: (j[Db.startedAt] as Timestamp?)?.toDate(),
        astrologerId: j[Db.astrologerId] as String? ?? '',
        astrologerName: j[Db.astrologerName] as String? ?? '',
        astrologerAvatar: j[Db.astrologerAvatar] as String? ?? '',
        type: ConsultType.values.firstWhere((t) => t.name == j[Db.type], orElse: () => ConsultType.chat),
        status: SessionStatus.values.firstWhere((s) => s.name == j[Db.status], orElse: () => SessionStatus.waiting),
        createdAt: (j[Db.createdAt] as Timestamp?)?.toDate() ?? DateTime.now(),
        durationSec: (j[Db.durationSec] as num? ?? 0).toInt(),
        cost: (j[Db.cost] as num? ?? 0).toDouble(),
        pricePerMin: (j[Db.pricePerMin] as num? ?? 0).toDouble(),
      );

  factory ConsultSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ConsultSession.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [id, status, durationSec, cost];
}

String formatDuration(int totalSeconds) {
  final h = totalSeconds ~/ AppConfig.secondsPerHour;
  final m = (totalSeconds % AppConfig.secondsPerHour) ~/ AppConfig.secondsPerMinute;
  final s = totalSeconds % AppConfig.secondsPerMinute;
  String two(int n) => n.toString().padLeft(2, AppConfig.padChar);
  final parts = [if (h > 0) two(h), two(m), two(s)];
  return parts.join(AppConfig.minuteSeparator);
}
