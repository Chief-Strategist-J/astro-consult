import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../astrologer_detail/astrologer_detail_view.dart';
import '../theme/app_states.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'astrologers_controller.dart';
import 'astrologers_model.dart';
import 'astrologers_state.dart';

extension AvailabilityStyle on Availability {
  Color color(BuildContext context) => switch (this) {
        Availability.online => context.tokens.success,
        Availability.busy => context.tokens.warning,
        Availability.offline => context.tokens.muted,
      };
}

class AstrologersView extends StatelessWidget {
  const AstrologersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.astrologersTitle), actions: [
        PopupMenuButton<AstrologerSort>(
          icon: const Icon(Icons.sort),
          tooltip: AppStrings.sort,
          onSelected: context.read<AstrologersCubit>().setSort,
          itemBuilder: (_) => [
            for (final s in AstrologerSort.values) PopupMenuItem(value: s, child: Text(s.label)),
          ],
        ),
        const ThemeToggleButton(),
      ]),
      body: BlocBuilder<AstrologersCubit, AstrologersState>(
        builder: (context, s) {
          final c = context.read<AstrologersCubit>();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.s),
              child: TextField(
                onChanged: c.setQuery,
                decoration: const InputDecoration(
                    hintText: AppStrings.searchHint, prefixIcon: Icon(Icons.search)),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Row(spacing: AppSpacing.s, children: [
                FilterChip(
                  label: const Text(AppStrings.onlineNow),
                  selected: s.onlyOnline,
                  onSelected: c.setOnlyOnline,
                ),
                for (final e in s.allExpertise)
                  FilterChip(
                    label: Text(e),
                    selected: s.expertise == e,
                    onSelected: (sel) => c.setExpertise(sel ? e : null),
                  ),
              ]),
            ),
            Expanded(child: _body(context, s, c)),
          ]);
        },
      ),
    );
  }

  Widget _body(BuildContext context, AstrologersState s, AstrologersCubit c) {
    if (s.loading && s.items.isEmpty) {
      return const AppShimmerList(avatarSize: 56, titleWidth: 150, subtitleWidth: 190, trailingWidth: 64);
    }
    if (s.error != null && s.items.isEmpty) {
      return AppErrorState(message: s.error!, onRetry: c.load, retryLabel: AppStrings.retry);
    }
    if (s.items.isEmpty) {
      return const AppEmptyState(icon: Icons.auto_awesome_outlined, title: AppStrings.noAstrologers);
    }
    final list = s.visible;
    if (list.isEmpty) {
      return const AppEmptyState(icon: Icons.search_off_rounded, title: AppStrings.noMatches);
    }
    return RefreshIndicator(
      onRefresh: c.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.page),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Padding(padding: EdgeInsets.only(top: AppSpacing.s)),
        itemBuilder: (_, i) => AstrologerCard(astrologer: list[i]),
      ),
    );
  }
}

class AstrologerCard extends StatelessWidget {
  const AstrologerCard({super.key, required this.astrologer});
  final Astrologer astrologer;

  @override
  Widget build(BuildContext context) {
    final a = astrologer;
    final muted = context.text.bodySmall?.copyWith(color: context.tokens.muted);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.m),
        onTap: () {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => AstrologerDetailView(astrologer: a)));
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: AppSpacing.m, children: [
            Stack(children: [
              Hero(
                tag: AppConfig.avatarHeroTag(a.id),
                child: AppAvatar(url: a.avatar, radius: 32),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: context.colors.surface,
                  child: CircleAvatar(radius: 6, backgroundColor: a.status.color(context)),
                ),
              ),
            ]),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: AppSpacing.xs, children: [
                Text(a.name, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(a.expertise.join(AppStrings.bullet), style: muted),
                Text(AppStrings.experienceLine(a.experience, a.languages), style: muted),
                Row(children: [
                  Icon(Icons.star_rounded, size: 18, color: context.colors.secondary),
                  Text(AppStrings.ratingWithCount(a.rating, a.reviews), style: context.text.bodySmall),
                  const Spacer(),
                  Text(AppStrings.perMinute(a.pricePerMin),
                      style: context.text.titleSmall?.copyWith(color: context.colors.primary)),
                ]),
                Text(a.status.label, style: context.text.labelSmall?.copyWith(color: a.status.color(context))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
