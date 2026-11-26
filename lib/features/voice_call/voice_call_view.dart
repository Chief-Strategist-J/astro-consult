import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../session/session_controller.dart';
import '../session/session_model.dart';
import '../session/session_state.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'voice_call_controller.dart';
import 'voice_call_model.dart';
import 'voice_call_state.dart';

class VoiceCallView extends StatelessWidget {
  const VoiceCallView({
    super.key,
    required this.session,
    @visibleForTesting this.previewCubit,
  });
  final ConsultSession session;
  final VoiceCallCubit? previewCubit;

  String _status(BuildContext context, VoiceCallState s) => switch (s.phase) {
    CallPhase.preparing => AppStrings.callPreparing,
    CallPhase.joining => AppStrings.callConnecting,
    CallPhase.waitingForPeer =>
      s.peerLeft
          ? AppStrings.peerLeft(session.counterpartName(context.myUid))
          : AppStrings.waitingPeer(session.counterpartName(context.myUid)),
    CallPhase.connected => AppStrings.callConnected,
    CallPhase.reconnecting => AppStrings.reconnecting,
    CallPhase.failed => s.error ?? AppStrings.callFailed,
  };

  @override
  Widget build(BuildContext context) {
    final name =
        context.read<AuthCubit>().state.user?.name ?? AppStrings.guestName;
    return BlocProvider(
      create: (_) => previewCubit ?? VoiceCallCubit(session.id, name),
      child: BlocConsumer<VoiceCallCubit, VoiceCallState>(
        listenWhen: (a, b) =>
            a.error != b.error &&
            b.error != null &&
            b.phase != CallPhase.failed,
        listener: (context, s) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.error!)));
          context.read<VoiceCallCubit>().clearError();
        },
        builder: (context, s) {
          final cubit = context.read<VoiceCallCubit>();
          final live =
              s.phase == CallPhase.connected ||
              s.phase == CallPhase.waitingForPeer;
          return Scaffold(
            body: SafeArea(
              // Scrolls when the screen is short (landscape / large text); spacers still centre the content otherwise.
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: box.maxHeight - AppSpacing.l * 2,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        spacing: AppSpacing.m,
                        children: [
                          const Spacer(),
                          AppAvatar(
                            url: session.counterpartAvatar(context.myUid),
                            radius: 64,
                          ),
                          Text(
                            session.counterpartName(context.myUid),
                            style: context.text.headlineSmall,
                          ),
                          Text(
                            _status(context, s),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: s.phase == CallPhase.failed
                                  ? context.colors.error
                                  : context.tokens.muted,
                            ),
                          ),
                          BlocBuilder<SessionCubit, SessionState>(
                            buildWhen: (a, b) => a.elapsed != b.elapsed,
                            builder: (_, ss) => Column(
                              children: [
                                Text(
                                  formatDuration(ss.elapsed),
                                  style: context.text.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                Text(
                                  AppStrings.soFar(ss.runningCost),
                                  style: TextStyle(color: context.tokens.muted),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (s.phase == CallPhase.failed)
                            FilledButton.tonal(
                              onPressed: cubit.start,
                              child: const Text(AppStrings.retry),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _RoundButton(
                                icon: s.micOn ? Icons.mic : Icons.mic_off,
                                label: s.micOn
                                    ? AppStrings.mute
                                    : AppStrings.unmute,
                                active: !s.micOn,
                                onTap: live ? cubit.toggleMic : null,
                              ),
                              BlocBuilder<SessionCubit, SessionState>(
                                buildWhen: (a, b) => a.ending != b.ending,
                                builder: (_, ss) => _RoundButton(
                                  icon: Icons.call_end,
                                  label: AppStrings.end,
                                  color: context.colors.error,
                                  onTap: ss.ending
                                      ? null
                                      : context.read<SessionCubit>().end,
                                ),
                              ),
                              if (!kIsWeb)
                                _RoundButton(
                                  icon: s.speakerOn
                                      ? Icons.volume_up
                                      : Icons.volume_down,
                                  label: AppStrings.speaker,
                                  active: s.speakerOn,
                                  onTap: live ? cubit.toggleSpeaker : null,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg =
        color ?? (active ? context.colors.primary : context.colors.surface);
    final fg = color != null
        ? context.colors.onError
        : (active ? context.colors.onPrimary : context.colors.onSurface);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        IconButton.filled(
          onPressed: onTap,
          iconSize: 28,
          style: IconButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: const EdgeInsets.all(AppSpacing.m),
            side: BorderSide(color: context.tokens.outline),
          ),
          icon: Icon(icon),
        ),
        Text(label, style: context.text.labelMedium),
      ],
    );
  }
}
