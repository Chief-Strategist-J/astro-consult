import 'package:equatable/equatable.dart';

import 'voice_call_model.dart';

class VoiceCallState extends Equatable {
  const VoiceCallState({
    this.phase = CallPhase.preparing,
    this.micOn = true,
    this.speakerOn = false,
    this.peerLeft = false,
    this.error,
  });

  final CallPhase phase;
  final bool micOn, speakerOn, peerLeft;
  final String? error;

  VoiceCallState copyWith({
    CallPhase? phase,
    bool? micOn,
    bool? speakerOn,
    bool? peerLeft,
    String? error,
    bool clearError = false,
  }) =>
      VoiceCallState(
        phase: phase ?? this.phase,
        micOn: micOn ?? this.micOn,
        speakerOn: speakerOn ?? this.speakerOn,
        peerLeft: peerLeft ?? this.peerLeft,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [phase, micOn, speakerOn, peerLeft, error];
}
