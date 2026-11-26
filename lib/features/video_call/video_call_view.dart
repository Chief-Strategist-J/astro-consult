import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:videosdk/videosdk.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../session/session_controller.dart';
import '../session/session_model.dart';
import '../session/session_state.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'video_call_controller.dart';
import 'video_call_model.dart';
import 'video_call_state.dart';

class VideoCallView extends StatelessWidget {
  const VideoCallView({super.key, required this.session, @visibleForTesting this.previewCubit});
  final ConsultSession session;
  final VideoCallCubit? previewCubit;

  String _status(BuildContext context, VideoCallState s) => switch (s.phase) {
        VideoPhase.preparing => AppStrings.callPreparing,
        VideoPhase.joining => AppStrings.callConnecting,
        VideoPhase.waitingForPeer =>
          s.peerLeft ? AppStrings.peerLeft(session.counterpartName(context.myUid)) : AppStrings.waitingPeer(session.counterpartName(context.myUid)),
        VideoPhase.connected => '',
        VideoPhase.reconnecting => AppStrings.reconnecting,
        VideoPhase.failed => s.error ?? AppStrings.callFailed,
      };

  @override
  Widget build(BuildContext context) {
    final name = context.read<AuthCubit>().state.user?.name ?? AppStrings.guestName;
    return BlocProvider(
      create: (_) => previewCubit ?? VideoCallCubit(session.id, name),
      child: BlocConsumer<VideoCallCubit, VideoCallState>(
        listenWhen: (a, b) => a.error != b.error && b.error != null && b.phase != VideoPhase.failed,
        listener: (context, s) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!)));
          context.read<VideoCallCubit>().clearError();
        },
        builder: (context, s) {
          final cubit = context.read<VideoCallCubit>();
          final remoteRenderer = s.remote?.cameraRenderer;
          final localRenderer = s.camOn ? s.local?.cameraRenderer : null;
          final status = _status(context, s);
          final live = s.phase == VideoPhase.connected || s.phase == VideoPhase.waitingForPeer;
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(fit: StackFit.expand, children: [
              if (remoteRenderer != null)
                RTCVideoView(remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
              else
                Center(child: AppAvatar(url: session.counterpartAvatar(context.myUid), radius: 64)),
              SafeArea(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Row(children: [
                      Expanded(
                        child: Text(session.counterpartName(context.myUid),
                            style: context.text.titleMedium?.copyWith(color: Colors.white)),
                      ),
                      BlocBuilder<SessionCubit, SessionState>(
                        buildWhen: (a, b) => a.elapsed != b.elapsed,
                        builder: (_, ss) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s + 2, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(AppRadius.l)),
                          child: Text(AppStrings.timerWithCost(formatDuration(ss.elapsed), ss.runningCost),
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                  if (status.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(AppRadius.s)),
                      child: Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    ),
                  if (s.phase == VideoPhase.failed)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.m),
                      child: FilledButton.tonal(onPressed: cubit.start, child: const Text(AppStrings.retry)),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: localRenderer == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              child: FractionallySizedBox(
                                widthFactor: 0.3,
                                child: AspectRatio(
                                  aspectRatio: 3 / 4,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.m),
                                    child: RTCVideoView(localRenderer,
                                        mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _Control(icon: s.micOn ? Icons.mic : Icons.mic_off, off: !s.micOn, onTap: live ? cubit.toggleMic : null),
                      _Control(
                          icon: s.camOn ? Icons.videocam : Icons.videocam_off,
                          off: !s.camOn,
                          onTap: live ? cubit.toggleCamera : null),
                      _Control(icon: Icons.cameraswitch, onTap: live && s.camOn ? cubit.switchCamera : null),
                      BlocBuilder<SessionCubit, SessionState>(
                        buildWhen: (a, b) => a.ending != b.ending,
                        builder: (_, ss) => _Control(
                          icon: Icons.call_end,
                          color: context.colors.error,
                          onTap: ss.ending ? null : context.read<SessionCubit>().end,
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.icon, this.onTap, this.off = false, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final bool off;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton.filled(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: color ?? (off ? Colors.white : Colors.white24),
          foregroundColor: off ? Colors.black : Colors.white,
          disabledBackgroundColor: Colors.white12,
          disabledForegroundColor: Colors.white38,
          padding: const EdgeInsets.all(AppSpacing.m),
        ),
        icon: Icon(icon),
      );
}
