import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:videosdk/videosdk.dart';

import '../../app_constants.dart';

class VideoRoom {
  const VideoRoom({required this.token, required this.meetingId});
  final String token, meetingId;

  factory VideoRoom.fromMap(Map<String, dynamic> j) =>
      VideoRoom(token: j[Fn.resToken] as String, meetingId: j[Fn.resMeetingId] as String);
}

enum VideoPhase { preparing, joining, waitingForPeer, connected, reconnecting, failed }

extension ParticipantVideo on Participant {

  RTCVideoRenderer? get cameraRenderer {
    for (final s in streams.values) {
      if (s.kind == MediaType.VIDEO) return s.renderer;
    }
    return null;
  }
}

/// The VideoSDK native library ships for ARM only, so calls cannot start on an x86 Android emulator or device.
bool get callsSupportedOnThisDevice => kIsWeb || !Platform.isAndroid || !Platform.version.contains('x64') && !Platform.version.contains('ia32');
