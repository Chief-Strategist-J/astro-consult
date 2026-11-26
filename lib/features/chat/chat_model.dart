import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../app_constants.dart';

class ChatMessage extends Equatable {
  const ChatMessage({required this.id, required this.text, required this.fromMe, required this.time, this.sent = true});
  final String id, text;
  final bool fromMe, sent;
  final DateTime time;

  factory ChatMessage.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc, String me) {
    final d = doc.data();
    return ChatMessage(
      id: doc.id,
      text: d[Db.messageText] as String? ?? '',
      fromMe: d[Db.messageFrom] == me,
      time: (d[Db.createdAt] as Timestamp?)?.toDate() ?? DateTime.now(),
      sent: !doc.metadata.hasPendingWrites,
    );
  }

  @override
  List<Object?> get props => [id, sent, time];
}
