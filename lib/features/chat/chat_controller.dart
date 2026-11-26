import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import 'chat_model.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this.sessionId, {required this.asAstrologer}) : super(const ChatState()) {
    _listen();
    _setPresence(typing: false);
    input.addListener(_onInput);
  }

  @visibleForTesting
  ChatCubit.preview(super.initialState, {this.asAstrologer = false}) : sessionId = '';

  final String sessionId;
  final bool asAstrologer;

  final input = TextEditingController();

  final List<StreamSubscription> _subs = [];
  Timer? _typingIdle;
  bool _typing = false;

  String get _me => asAstrologer ? Db.fromAstrologer : Db.fromUser;
  String get _peer => asAstrologer ? Db.fromUser : Db.fromAstrologer;
  DocumentReference<Map<String, dynamic>> get _session => Backend.db.collection(Db.sessions).doc(sessionId);

  void _listen() {
    _subs.add(_session.collection(Db.messages).orderBy(Db.createdAt, descending: true).snapshots(includeMetadataChanges: true).listen(
      (snap) => emit(state.copyWith(
        messages: snap.docs.map((d) => ChatMessage.fromDoc(d, _me)).toList(),
        connected: !snap.metadata.isFromCache,
        clearError: true,
      )),
      onError: (Object e) => emit(state.copyWith(connected: false, error: Backend.message(e))),
    ));
    _subs.add(_session.collection(Db.presence).doc(_peer).snapshots().listen(
      (doc) => emit(state.copyWith(
        peerOnline: doc.data()?[Db.online] as bool? ?? false,
        typing: doc.data()?[Db.typing] as bool? ?? false,
      )),
      onError: (_) {},
    ));
  }

  /// Best effort: indicators must never break chatting (for example after the session has ended).
  Future<void> _setPresence({required bool typing, bool online = true}) async {
    try {
      await _session.collection(Db.presence).doc(_me).set({
        Db.online: online,
        Db.typing: typing,
        Db.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _onInput() {
    final hasText = input.text.trim().isNotEmpty;
    if (hasText && !_typing) {
      _typing = true;
      _setPresence(typing: true);
    }
    _typingIdle?.cancel();
    if (_typing) _typingIdle = Timer(AppConfig.typingIdle, _stopTyping);
  }

  void _stopTyping() {
    if (!_typing) return;
    _typing = false;
    _typingIdle?.cancel();
    _setPresence(typing: false);
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    input.clear();
    _stopTyping();
    try {
      await _session.collection(Db.messages).add({
        Db.messageText: text,
        Db.messageFrom: _me,
        Db.createdAt: FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: AppStrings.errSend));
    }
  }

  @override
  Future<void> close() {
    _typingIdle?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _setPresence(typing: false, online: false);
    input.removeListener(_onInput);
    input.dispose();
    return super.close();
  }
}
