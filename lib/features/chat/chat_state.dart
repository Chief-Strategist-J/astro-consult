import 'package:equatable/equatable.dart';

import 'chat_model.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const [],
    this.connected = false,
    this.peerOnline = false,
    this.typing = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool connected, peerOnline, typing;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? connected,
    bool? peerOnline,
    bool? typing,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        connected: connected ?? this.connected,
        peerOnline: peerOnline ?? this.peerOnline,
        typing: typing ?? this.typing,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [messages, connected, peerOnline, typing, error];
}
