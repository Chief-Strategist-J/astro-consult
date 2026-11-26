import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../chat/chat_view.dart';
import '../theme/app_states.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import '../video_call/video_call_view.dart';
import '../voice_call/voice_call_view.dart';
import 'session_controller.dart';
import 'session_model.dart';
import 'session_state.dart';

class SessionFlowView extends StatelessWidget {
  const SessionFlowView({super.key});

  static Future<void> confirmEnd(BuildContext context) async {
    final cubit = context.read<SessionCubit>();
    if (ModalRoute.of(context)?.isCurrent != true || cubit.state.ending) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text(AppStrings.endTitle),
        content: const Text(AppStrings.endBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text(AppStrings.keepGoing)),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text(AppStrings.end)),
        ],
      ),
    );
    if (ok ?? false) cubit.end();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionCubit, SessionState>(
      listenWhen: (a, b) =>
          (a.phase == SessionPhase.ongoing && b.phase == SessionPhase.ongoing && a.error != b.error && b.error != null) ||
          (b.phase == SessionPhase.idle && a.phase != SessionPhase.idle),
      listener: (context, s) {
        if (s.phase == SessionPhase.idle) {
          Navigator.of(context).maybePop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!)));
        }
      },
      builder: (context, s) {
        final cubit = context.read<SessionCubit>();
        if (s.phase == SessionPhase.idle) return const Scaffold();
        return PopScope(
          canPop: s.phase == SessionPhase.failed || s.phase == SessionPhase.completed || s.phase == SessionPhase.idle,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (s.phase == SessionPhase.ongoing) {
              confirmEnd(context);
            } else if (s.phase == SessionPhase.waiting) {
              cubit.end();
            }
          },
          child: switch (s.phase) {
            SessionPhase.starting || SessionPhase.waiting => _Waiting(state: s),
            SessionPhase.ongoing => switch (s.session!.type) {
                ConsultType.chat => ChatView(session: s.session!),
                ConsultType.voice => VoiceCallView(session: s.session!),
                ConsultType.video => VideoCallView(session: s.session!),
              },
            SessionPhase.completed => _Summary(session: s.session!),
            _ => _Failed(message: s.error ?? AppStrings.failedGeneric),
          },
        );
      },
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.state});
  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final s = state.session;
    // An astrologer who just accepted only sees a brief "connecting" state; users wait for an answer.
    final astrologerSide = s?.isAstrologer(context.myUid) ?? false;
    return Scaffold(
      body: SafeArea(
        child: AppStatusView(
          leading: s == null ? null : AppAvatar(url: s.counterpartAvatar(context.myUid), radius: 52),
          title: s == null
              ? AppStrings.sendingRequest
              : (astrologerSide ? AppStrings.callConnecting : AppStrings.waitingFor(s.astrologerName)),
          message: s == null || astrologerSide
              ? null
              : (state.reconnecting ? AppStrings.reconnecting : AppStrings.requestSent(s.type.label)),
          content: const [Center(child: CircularProgressIndicator())],
          actions: [
            if (!astrologerSide)
              OutlinedButton(
                onPressed: state.ending || s == null ? null : context.read<SessionCubit>().end,
                child: const Text(AppStrings.cancelRequest),
              ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.session});
  final ConsultSession session;

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(spacing: AppSpacing.m, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(k, style: TextStyle(color: context.tokens.muted)),
            Flexible(child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );
    return Scaffold(
      body: SafeArea(
        child: AppStatusView(
          leading: AppStatusIcon(icon: Icons.check_circle_rounded, color: context.tokens.success),
          title: AppStrings.completedTitle,
          content: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(children: [
                  row(session.isAstrologer(context.myUid) ? AppStrings.rowClient : AppStrings.rowAstrologer,
                      session.counterpartName(context.myUid)),
                  row(AppStrings.rowType, session.type.label),
                  row(AppStrings.rowDuration, formatDuration(session.durationSec)),
                  row(AppStrings.rowRate, AppStrings.perMinute(session.pricePerMin)),
                  const Divider(),
                  row(AppStrings.rowTotal, AppStrings.moneyExact(session.cost)),
                ]),
              ),
            ),
          ],
          actions: [
            FilledButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await context.read<SessionCubit>().reset();
                nav.pop();
              },
              child: const Text(AppStrings.done),
            ),
          ],
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AppStatusView(
            leading: AppStatusIcon(icon: Icons.error_outline_rounded, color: context.colors.error),
            title: AppStrings.failedTitle,
            message: message,
            actions: [
              FilledButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await context.read<SessionCubit>().reset();
                  nav.pop();
                },
                child: const Text(AppStrings.close),
              ),
            ],
          ),
        ),
      );
}

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historyTitle), actions: const [ThemeToggleButton()]),
      body: BlocBuilder<SessionCubit, SessionState>(
        buildWhen: (a, b) =>
            a.history != b.history || a.historyLoading != b.historyLoading || a.historyError != b.historyError,
        builder: (context, s) {
          final cubit = context.read<SessionCubit>();
          if (s.historyLoading && s.history.isEmpty) {
            return const AppShimmerList(avatarSize: 44, titleWidth: 130, subtitleWidth: 170, trailingWidth: 56);
          }
          if (s.historyError != null && s.history.isEmpty) {
            return AppErrorState(message: s.historyError!, onRetry: cubit.loadHistory, retryLabel: AppStrings.retry);
          }
          return RefreshIndicator(
            onRefresh: cubit.loadHistory,
            child: s.history.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: const AppEmptyState(icon: Icons.history_rounded, title: AppStrings.noHistory),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    itemCount: s.history.length,
                    separatorBuilder: (_, _) => const Padding(padding: EdgeInsets.only(top: AppSpacing.s)),
                    itemBuilder: (_, i) {
                      final h = s.history[i];
                      final cancelled = h.status == SessionStatus.cancelled;
                      final declined = h.status == SessionStatus.rejected;
                      return Card(
                        child: ListTile(
                          leading: AppAvatar(url: h.astrologerAvatar, radius: 20),
                          title: Text(h.astrologerName),
                          subtitle: Text(AppStrings.historySubtitle(
                            h.type.label,
                            DateFormat(AppConfig.historyDateFormat).format(h.createdAt),
                            declined
                                ? AppStrings.declined
                                : (cancelled ? AppStrings.cancelled : AppStrings.durationLabel(formatDuration(h.durationSec))),
                          )),
                          isThreeLine: true,
                          trailing: Text(cancelled || declined ? AppStrings.dash : AppStrings.money(h.cost),
                              style: context.text.titleSmall),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
