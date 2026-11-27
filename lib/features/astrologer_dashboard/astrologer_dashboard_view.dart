import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app_constants.dart';
import '../astrologers/astrologers_model.dart';
import '../astrologers/astrologers_view.dart';
import '../session/session_controller.dart';
import '../session/session_model.dart';
import '../session/session_view.dart';
import '../theme/app_states.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'astrologer_dashboard_controller.dart';
import 'astrologer_dashboard_state.dart';

class AstrologerDashboardView extends StatelessWidget {
  const AstrologerDashboardView({super.key, @visibleForTesting this.previewCubit});
  final AstrologerDashboardCubit? previewCubit;

  /// Joins the consultation (chat / voice / video) on the astrologer's side.
  void _open(BuildContext context, ConsultSession s) {
    context.read<SessionCubit>().attach(s);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SessionFlowView()));
  }

  Future<void> _accept(BuildContext context, ConsultSession s) async {
    final ok = await context.read<AstrologerDashboardCubit>().respond(s, accept: true);
    if (ok && context.mounted) _open(context, s);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => previewCubit ?? AstrologerDashboardCubit(),
      child: BlocConsumer<AstrologerDashboardCubit, AstrologerDashboardState>(
        listenWhen: (a, b) => a.error != b.error && b.error != null,
        listener: (context, s) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!)));
          context.read<AstrologerDashboardCubit>().clearError();
        },
        builder: (context, s) {
          final cubit = context.read<AstrologerDashboardCubit>();
          final acc = s.account;
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.dashboardTitle), actions: const [ThemeToggleButton()]),
            body: s.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.section, children: [
                      if (acc != null) _AccountCard(state: s, onToggle: cubit.setOnline),
                      if (s.active != null)
                        AppSection(title: AppStrings.activeConsultation, children: [
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.phone_in_talk_rounded, color: context.tokens.success),
                              title: Text(AppStrings.requestTitle(s.active!.userName, s.active!.type.label)),
                              trailing: Row(mainAxisSize: MainAxisSize.min, spacing: AppSpacing.s, children: [
                                OutlinedButton(
                                  onPressed: () => cubit.endActive(s.active!),
                                  child: const Text(AppStrings.endConsultation),
                                ),
                                FilledButton(
                                  onPressed: () => _open(context, s.active!),
                                  child: const Text(AppStrings.resume),
                                ),
                              ]),
                            ),
                          ),
                        ]),
                      AppSection(title: AppStrings.incomingRequests, children: [
                        if (s.requests.isEmpty) const AppEmptyRow(icon: Icons.inbox_outlined, text: AppStrings.noRequests),
                        for (final r in s.requests)
                          _RequestCard(
                            request: r,
                            busy: s.respondingId != null,
                            onAccept: () => _accept(context, r),
                            onDecline: () => cubit.respond(r, accept: false),
                          ),
                      ]),
                      AppSection(title: AppStrings.recentConsultations, children: [
                        if (s.history.isEmpty) const AppEmptyRow(icon: Icons.history_rounded, text: AppStrings.noRecent),
                        for (final h in s.history) _HistoryTile(session: h),
                      ]),
                    ]),
                  ),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.state, required this.onToggle});
  final AstrologerDashboardState state;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final a = state.account!;
    final label = switch (a.status) {
      Availability.online => AppStrings.youAreOnline,
      Availability.busy => AppStrings.youAreBusy,
      Availability.offline => AppStrings.youAreOffline,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(spacing: AppSpacing.s, children: [
          Row(spacing: AppSpacing.m, children: [
            AppAvatar(url: a.avatar, radius: 28),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: context.text.titleMedium),
                Text(
                  '${a.isNew ? AppStrings.newAstrologer : AppStrings.ratingStat(a.rating)}${AppStrings.bullet}${AppStrings.perMinute(a.pricePerMin)}',
                  style: context.text.bodySmall,
                ),
              ]),
            ),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label, style: TextStyle(color: a.status.color(context), fontWeight: FontWeight.w600)),
            subtitle: const Text(AppStrings.availabilityHint),
            value: a.status != Availability.offline,
            onChanged: state.togglingAvailability ? null : onToggle,
          ),
        ]),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.busy, required this.onAccept, required this.onDecline});
  final ConsultSession request;
  final bool busy;
  final VoidCallback onAccept, onDecline;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final hasBirth = (r.userDob?.isNotEmpty ?? false) && (r.userBirthPlace?.isNotEmpty ?? false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.s, children: [
          Row(spacing: AppSpacing.s, children: [
            Icon(switch (r.type) {
              ConsultType.chat => Icons.chat_bubble_outline,
              ConsultType.voice => Icons.call_outlined,
              ConsultType.video => Icons.videocam_outlined,
            }, color: context.colors.primary),
            Expanded(
              child: Text(AppStrings.requestTitle(r.userName, r.type.label), style: context.text.titleSmall),
            ),
            Text(DateFormat(AppConfig.messageTimeFormat).format(r.createdAt), style: context.text.labelSmall),
          ]),
          if (hasBirth)
            Text(AppStrings.clientBirth(r.userDob!, r.userBirthTime ?? AppStrings.dash, r.userBirthPlace!),
                style: context.text.bodySmall),
          Row(spacing: AppSpacing.s, children: [
            Expanded(child: OutlinedButton(onPressed: busy ? null : onDecline, child: const Text(AppStrings.decline))),
            Expanded(child: FilledButton(onPressed: busy ? null : onAccept, child: const Text(AppStrings.accept))),
          ]),
        ]),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.session});
  final ConsultSession session;

  @override
  Widget build(BuildContext context) {
    final h = session;
    final declined = h.status == SessionStatus.rejected;
    final cancelled = h.status == SessionStatus.cancelled;
    return Card(
      child: ListTile(
        leading: const AppAvatar(url: '', radius: 20),
        title: Text(h.userName),
        subtitle: Text(AppStrings.historySubtitle(
          h.type.label,
          DateFormat(AppConfig.historyDateFormat).format(h.createdAt),
          declined ? AppStrings.declined : (cancelled ? AppStrings.cancelled : AppStrings.durationLabel(formatDuration(h.durationSec))),
        )),
        isThreeLine: true,
        trailing: Text(declined || cancelled ? AppStrings.dash : AppStrings.earned(AppStrings.money(h.cost)),
            style: context.text.titleSmall),
      ),
    );
  }
}
