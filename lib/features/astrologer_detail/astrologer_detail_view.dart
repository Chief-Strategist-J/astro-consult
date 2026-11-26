import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../astrologers/astrologers_model.dart';
import '../astrologers/astrologers_view.dart';
import '../session/session_controller.dart';
import '../session/session_model.dart';
import '../session/session_state.dart';
import '../session/session_view.dart';
import '../theme/app_states.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'astrologer_detail_controller.dart';
import 'astrologer_detail_state.dart';

class AstrologerDetailView extends StatelessWidget {
  const AstrologerDetailView({super.key, required this.astrologer, @visibleForTesting this.previewCubit});
  final Astrologer astrologer;
  final AstrologerDetailCubit? previewCubit;

  void _consult(BuildContext context, Astrologer a, ConsultType type) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final session = context.read<SessionCubit>();
    final phase = session.state.phase;
    if (phase == SessionPhase.starting || phase == SessionPhase.waiting || phase == SessionPhase.ongoing) {
      return;
    }
    session.start(a, type);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SessionFlowView()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => previewCubit ?? AstrologerDetailCubit(astrologer),
      child: BlocBuilder<AstrologerDetailCubit, AstrologerDetailState>(
        builder: (context, s) {
          final a = s.astrologer;
          return Scaffold(
            appBar: AppBar(title: Text(a.name)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.section, children: [
                Column(spacing: AppSpacing.s, children: [
                  Hero(tag: AppConfig.avatarHeroTag(a.id), child: AppAvatar(url: a.avatar, radius: 52)),
                  Text(a.name, textAlign: TextAlign.center, style: context.text.headlineSmall),
                  Text(a.status.label, style: TextStyle(color: a.status.color(context), fontWeight: FontWeight.w600)),
                ]),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    child: Row(children: [
                      _Stat(label: AppStrings.statRating, value: AppStrings.ratingStat(a.rating)),
                      _Stat(label: AppStrings.statExperience, value: AppStrings.years(a.experience)),
                      _Stat(label: AppStrings.statReviews, value: AppStrings.count(a.reviews)),
                      _Stat(label: AppStrings.statPrice, value: AppStrings.perMinute(a.pricePerMin)),
                    ]),
                  ),
                ),
                AppSection(title: AppStrings.about, children: [
                  Text(a.about, style: TextStyle(color: context.tokens.muted)),
                  Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [for (final e in a.expertise) Chip(label: Text(e))]),
                  Text(AppStrings.languages(a.languages), style: TextStyle(color: context.tokens.muted)),
                ]),
                AppSection(title: AppStrings.reviews, children: [
                  if (s.loading) ...[
                    const AppShimmer(height: 68, radius: AppRadius.m),
                    const AppShimmer(height: 68, radius: AppRadius.m),
                  ] else if (s.error != null)
                    AppErrorState(message: s.error!, onRetry: context.read<AstrologerDetailCubit>().load)
                  else if (s.reviews.isEmpty)
                    const AppEmptyRow(icon: Icons.rate_review_outlined, text: AppStrings.noReviews)
                  else
                    for (final r in s.reviews)
                      Card(
                        child: ListTile(
                          title: Text(AppStrings.reviewTitle(r.user, r.rating)),
                          subtitle: Text(r.text),
                        ),
                      ),
                ]),
              ]),
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.tokens.outline)),
                ),
                padding: const EdgeInsets.all(AppSpacing.page),
                child: a.isOnline
                    ? Row(spacing: AppSpacing.s, children: [
                        for (final t in ConsultType.values)
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s)),
                              onPressed: () => _consult(context, a, t),
                              icon: Icon(switch (t) {
                                ConsultType.chat => Icons.chat_bubble_outline,
                                ConsultType.voice => Icons.call_outlined,
                                ConsultType.video => Icons.videocam_outlined,
                              }),
                              label: Text(switch (t) {
                                ConsultType.chat => AppStrings.actionChat,
                                ConsultType.voice => AppStrings.actionCall,
                                ConsultType.video => AppStrings.actionVideo,
                              }),
                            ),
                          ),
                      ])
                    : Text(AppStrings.unavailable(a.name, a.status.label.toLowerCase()),
                        textAlign: TextAlign.center, style: TextStyle(color: context.tokens.muted)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: context.text.labelSmall?.copyWith(color: context.tokens.muted)),
        ]),
      );
}
