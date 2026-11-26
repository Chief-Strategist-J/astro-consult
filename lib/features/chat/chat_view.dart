import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../session/session_controller.dart';
import '../session/session_model.dart';
import '../session/session_state.dart';
import '../session/session_view.dart';
import '../theme/app_states.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'chat_controller.dart';
import 'chat_model.dart';
import 'chat_state.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key, required this.session, @visibleForTesting this.previewCubit});
  final ConsultSession session;
  final ChatCubit? previewCubit;

  @override
  Widget build(BuildContext context) {
    final a = session;
    return BlocProvider(
      create: (_) => previewCubit ?? ChatCubit(a.id, asAstrologer: a.isAstrologer(context.myUid)),
      child: BlocConsumer<ChatCubit, ChatState>(
        listenWhen: (p, n) => p.error != n.error && n.error != null,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
        builder: (context, s) {
          final cubit = context.read<ChatCubit>();
          return Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: Row(spacing: AppSpacing.s, children: [
                AppAvatar(url: a.counterpartAvatar(context.myUid), radius: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.counterpartName(context.myUid), style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                    Text(
                      s.typing ? AppStrings.typing : (s.peerOnline ? AppStrings.online : AppStrings.offline),
                      style: context.text.labelSmall?.copyWith(
                          color: s.peerOnline ? context.tokens.success : context.tokens.muted),
                    ),
                  ]),
                ),
              ]),
              actions: [
                BlocBuilder<SessionCubit, SessionState>(
                  buildWhen: (p, n) => p.elapsed != n.elapsed || p.ending != n.ending,
                  builder: (context, ss) => Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s + 2, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.l),
                      ),
                      child: Text(formatDuration(ss.elapsed),
                          style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      tooltip: AppStrings.endChat,
                      icon: Icon(Icons.call_end, color: context.colors.error),
                      onPressed: ss.ending ? null : () => SessionFlowView.confirmEnd(context),
                    ),
                  ]),
                ),
              ],
            ),
            body: Column(children: [
              if (!s.connected)
                Container(
                  width: double.infinity,
                  color: context.tokens.warning.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: Text(AppStrings.connecting, textAlign: TextAlign.center),
                ),
              Expanded(
                child: s.messages.isEmpty
                    ? AppEmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: AppStrings.sayHello(a.counterpartName(context.myUid).split(' ').first))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(AppSpacing.page),
                        itemCount: s.messages.length,
                        itemBuilder: (_, i) => _Bubble(message: s.messages[i]),
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: Row(spacing: AppSpacing.s, children: [
                    Expanded(
                      child: TextField(
                        controller: cubit.input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: AppConfig.maxMessageLength,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => cubit.send(),
                        decoration: const InputDecoration(hintText: AppStrings.messageHint),
                      ),
                    ),
                    IconButton.filled(onPressed: cubit.send, icon: const Icon(Icons.send)),
                  ]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final fg = m.fromMe ? context.colors.onPrimary : context.colors.onSurface;
    final faded = fg.withValues(alpha: 0.7);
    return Align(
      alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s + 4, vertical: AppSpacing.s),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          color: m.fromMe ? context.colors.primary : context.colors.surface,
          border: m.fromMe ? null : Border.all(color: context.tokens.outline),
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text(m.text, style: TextStyle(color: fg)),
          Row(mainAxisSize: MainAxisSize.min, spacing: AppSpacing.xs, children: [
            Text(DateFormat(AppConfig.messageTimeFormat).format(m.time),
                style: context.text.labelSmall?.copyWith(color: faded)),
            if (m.fromMe) Icon(m.sent ? Icons.done : Icons.access_time, size: 12, color: faded),
          ]),
        ]),
      ),
    );
  }
}
