import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videosdk/videosdk.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import 'video_call_model.dart';
import 'video_call_state.dart';

class VideoCallCubit extends Cubit<VideoCallState> {
  VideoCallCubit(this.sessionId, this.displayName) : super(const VideoCallState()) {
    start();
  }

  /// Layout previews / widget tests: renders [initial] without joining a VideoSDK room.
  @visibleForTesting
  VideoCallCubit.preview(super.initialState)
      : sessionId = '',
        displayName = '';

  final String sessionId, displayName;
  Room? _room;
  bool _joined = false, _closed = false;

  Future<void> start() async {
    emit(const VideoCallState());
    try {
      final perm = await VideoSDK.requestPermissions(Permissions.AUDIO_VIDEO);
      if (perm[AppConfig.permAudio] != true || perm[AppConfig.permVideo] != true) {
        return emit(state.copyWith(
            phase: VideoPhase.failed, error: AppStrings.errCamPermission));
      }
      final vr = VideoRoom.fromMap(await Backend.call(Fn.getVideoSdkRoom, {Fn.argSessionId: sessionId}));
      if (_closed) return;
      await _disposeRoom();
      final room = VideoSDK.createRoom(
        roomId: vr.meetingId,
        token: vr.token,
        participantName: displayName,
        micEnabled: true,
        camEnabled: true,
      );
      _room = room;
      _wire(room);
      emit(state.copyWith(phase: VideoPhase.joining));
      await room.join();
    } catch (e) {
      if (!_closed) emit(state.copyWith(phase: VideoPhase.failed, error: Backend.message(e)));
    }
  }

  Participant? _firstRemote(Room room) => room.participants.values.isEmpty ? null : room.participants.values.first;

  void _wire(Room room) {
    void bump() => _safe(() => emit(state.copyWith(rev: state.rev + 1)));

    room.on(Events.roomJoined, () {
      _joined = true;
      final remote = _firstRemote(room);
      _safe(() => emit(state.copyWith(
            phase: remote == null ? VideoPhase.waitingForPeer : VideoPhase.connected,
            local: room.localParticipant,
            remote: remote,
            clearRemote: remote == null,
            peerLeft: false,
            clearError: true,
          )));
    });
    room.on(Events.participantJoined, (Participant p) {
      _safe(() => emit(state.copyWith(phase: VideoPhase.connected, remote: p, peerLeft: false)));
    });
    room.on(Events.participantLeft, (Participant p, LeaveReason r) {
      _safe(() => emit(state.copyWith(phase: VideoPhase.waitingForPeer, clearRemote: true, peerLeft: true)));
    });
    room.on(Events.streamEnabled, (RTCStream s) => bump());
    room.on(Events.streamDisabled, (RTCStream s) => bump());
    room.on(Events.roomStateChanged, (RoomState s) {
      if (!_joined) return;
      if (s == RoomState.RECONNECTING) {
        _safe(() => emit(state.copyWith(phase: VideoPhase.reconnecting)));
      } else if (s == RoomState.CONNECTED) {
        _safe(() => emit(state.copyWith(
            phase: state.remote == null ? VideoPhase.waitingForPeer : VideoPhase.connected)));
      }
    });
    room.on(Events.roomLeft, (LeaveReason? reason) {
      if (_closed) return;
      _joined = false;
      _safe(() => emit(state.copyWith(phase: VideoPhase.failed, error: AppStrings.errDisconnected)));
    });
    room.on(Events.error, (VideoSDKError e) {
      _safe(() => emit(state.copyWith(error: e.message.isEmpty ? e.name : e.message)));
    });
  }

  void _safe(void Function() f) {
    if (!_closed) f();
  }

  Future<void> toggleMic() async {
    final room = _room;
    if (room == null || !_joined) return;
    try {
      state.micOn ? await room.muteMic() : await room.unmuteMic();
      emit(state.copyWith(micOn: !state.micOn));
    } catch (_) {
      emit(state.copyWith(error: AppStrings.errMicToggle));
    }
  }

  Future<void> toggleCamera() async {
    final room = _room;
    if (room == null || !_joined) return;
    try {
      state.camOn ? await room.disableCam() : await room.enableCam();
      emit(state.copyWith(camOn: !state.camOn));
    } catch (_) {
      emit(state.copyWith(error: AppStrings.errCamToggle));
    }
  }

  Future<void> switchCamera() async {
    final room = _room;
    if (room == null || !_joined || !state.camOn) return;
    try {
      await room.changeCam();
    } catch (_) {
      emit(state.copyWith(error: AppStrings.errCamSwitch));
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));

  Future<void> _disposeRoom() async {
    final room = _room;
    _room = null;
    if (room == null) return;
    room.removeAllEventListeners();
    try {
      await room.leave();
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _disposeRoom();
    return super.close();
  }
}
