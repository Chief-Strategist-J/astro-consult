import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videosdk/videosdk.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../video_call/video_call_model.dart' show callsSupportedOnThisDevice;
import 'voice_call_model.dart';
import 'voice_call_state.dart';

class VoiceCallCubit extends Cubit<VoiceCallState> {
  VoiceCallCubit(this.sessionId, this.displayName) : super(const VoiceCallState()) {
    start();
  }

  /// Layout previews / widget tests: renders [initial] without joining a VideoSDK room.
  @visibleForTesting
  VoiceCallCubit.preview(super.initialState)
      : sessionId = '',
        displayName = '';

  final String sessionId, displayName;
  Room? _room;
  bool _joined = false, _closed = false;

  Future<void> start() async {
    emit(const VoiceCallState());
    if (!callsSupportedOnThisDevice) {
      return emit(state.copyWith(phase: CallPhase.failed, error: AppStrings.errUnsupportedDevice));
    }
    try {
      final perm = await VideoSDK.requestPermissions(Permissions.AUDIO);
      if (perm[AppConfig.permAudio] != true) {
        return emit(state.copyWith(phase: CallPhase.failed, error: AppStrings.errMicPermission));
      }
      final cr = CallRoom.fromMap(await Backend.call(Fn.getVideoSdkRoom, {Fn.argSessionId: sessionId}));
      if (_closed) return;
      await _disposeRoom();
      final room = VideoSDK.createRoom(
        roomId: cr.meetingId,
        token: cr.token,
        participantName: displayName,
        micEnabled: true,
        camEnabled: false,
      );
      _room = room;
      _wire(room);
      emit(state.copyWith(phase: CallPhase.joining));
      await room.join();
    } catch (e) {
      if (!_closed) emit(state.copyWith(phase: CallPhase.failed, error: Backend.message(e)));
    }
  }

  void _wire(Room room) {
    room.on(Events.roomJoined, () {
      _joined = true;
      bool onSpeaker = false;
      if (!kIsWeb) {
        try {
          final sel = VideoSDK.getSelectedAudioDevice();
          onSpeaker = (sel?.label ?? '').toLowerCase().contains(AppConfig.speakerKeyword);
        } catch (_) {}
      }
      _safe(() => emit(state.copyWith(
            phase: room.participants.isEmpty ? CallPhase.waitingForPeer : CallPhase.connected,
            speakerOn: onSpeaker,
            peerLeft: false,
            clearError: true,
          )));
    });
    room.on(Events.participantJoined, (Participant p) {
      _safe(() => emit(state.copyWith(phase: CallPhase.connected, peerLeft: false)));
    });
    room.on(Events.participantLeft, (Participant p, LeaveReason r) {
      _safe(() => emit(state.copyWith(phase: CallPhase.waitingForPeer, peerLeft: true)));
    });
    room.on(Events.roomStateChanged, (RoomState s) {
      if (!_joined) return;
      if (s == RoomState.RECONNECTING) {
        _safe(() => emit(state.copyWith(phase: CallPhase.reconnecting)));
      } else if (s == RoomState.CONNECTED) {
        _safe(() => emit(state.copyWith(
            phase: room.participants.isEmpty ? CallPhase.waitingForPeer : CallPhase.connected)));
      }
    });
    room.on(Events.roomLeft, (LeaveReason? reason) {
      if (_closed) return;
      _joined = false;
      _safe(() => emit(state.copyWith(phase: CallPhase.failed, error: AppStrings.errDisconnected)));
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

  Future<void> toggleSpeaker() async {
    final room = _room;
    if (room == null || !_joined) return;
    final wantSpeaker = !state.speakerOn;
    try {
      final devices = await VideoSDK.getMics() ?? const [];
      final match = devices.where((d) {
        final l = AppConfig.deviceKey(d.label, d.deviceId);
        return wantSpeaker
            ? l.contains(AppConfig.speakerKeyword)
            : AppConfig.earpieceKeywords.any(l.contains);
      }).firstOrNull;
      if (match == null) {
        return emit(state.copyWith(
            error: AppStrings.errOutputMissing(wantSpeaker ? AppStrings.outputSpeaker : AppStrings.outputEarpiece)));
      }
      await room.changeMic(deviceId: match.deviceId);
      emit(state.copyWith(speakerOn: wantSpeaker));
    } catch (_) {
      emit(state.copyWith(error: AppStrings.errSpeakerSwitch));
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
