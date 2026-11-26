import '../../app_constants.dart';

/// Credentials returned by the `getVideoSdkRoom` Cloud Function.
class CallRoom {
  const CallRoom({required this.token, required this.meetingId});
  final String token, meetingId;

  factory CallRoom.fromMap(Map<String, dynamic> j) =>
      CallRoom(token: j[Fn.resToken] as String, meetingId: j[Fn.resMeetingId] as String);
}

enum CallPhase { preparing, joining, waitingForPeer, connected, reconnecting, failed }
