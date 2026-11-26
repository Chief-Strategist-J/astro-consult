import 'package:equatable/equatable.dart';
import 'package:videosdk/videosdk.dart';

import 'video_call_model.dart';

class VideoCallState extends Equatable {
  const VideoCallState({
    this.phase = VideoPhase.preparing,
    this.micOn = true,
    this.camOn = true,
    this.peerLeft = false,
    this.local,
    this.remote,
    this.rev = 0,
    this.error,
  });

  final VideoPhase phase;
  final bool micOn, camOn, peerLeft;
  final Participant? local, remote;
  final int rev;
  final String? error;

  VideoCallState copyWith({
    VideoPhase? phase,
    bool? micOn,
    bool? camOn,
    bool? peerLeft,
    Participant? local,
    Participant? remote,
    bool clearRemote = false,
    int? rev,
    String? error,
    bool clearError = false,
  }) =>
      VideoCallState(
        phase: phase ?? this.phase,
        micOn: micOn ?? this.micOn,
        camOn: camOn ?? this.camOn,
        peerLeft: peerLeft ?? this.peerLeft,
        local: local ?? this.local,
        remote: clearRemote ? null : (remote ?? this.remote),
        rev: rev ?? this.rev,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [phase, micOn, camOn, peerLeft, local?.id, remote?.id, rev, error];
}
