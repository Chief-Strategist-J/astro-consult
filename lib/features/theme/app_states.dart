import 'package:flutter/material.dart';

import '../../app_constants.dart';
import 'theme_model.dart';

class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, this.width = double.infinity, this.height = 16, this.radius = AppRadius.s});

  final double width;
  final double height;
  final double radius;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.surfaceContainer;
    final highlight = context.colors.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

class AppShimmerList extends StatelessWidget {
  const AppShimmerList({
    super.key,
    this.itemCount = 6,
    this.avatarSize = 52,
    this.titleWidth = 140,
    this.subtitleWidth = 200,
    this.trailingWidth,
  });

  final int itemCount;
  final double avatarSize;
  final double titleWidth;
  final double subtitleWidth;
  final double? trailingWidth;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.page),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Padding(padding: EdgeInsets.only(top: AppSpacing.s)),
      itemBuilder: (_, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            spacing: AppSpacing.m,
            children: [
              AppShimmer(width: avatarSize, height: avatarSize, radius: AppRadius.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s,
                  children: [
                    AppShimmer(width: titleWidth, height: 16),
                    AppShimmer(width: subtitleWidth, height: 12),
                  ],
                ),
              ),
              if (trailingWidth != null) AppShimmer(width: trailingWidth!, height: 28, radius: AppRadius.s),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round tinted badge holding a status icon. Colour carries the meaning (muted / error / success / primary).
class AppStatusIcon extends StatelessWidget {
  const AppStatusIcon({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, size: 40, color: color),
      );
}

/// The one layout for every "hero" screen (waiting, summary, failed, empty, error): everything is centred,
/// text is centred, buttons are full width, and short screens scroll instead of overflowing.
class AppStatusView extends StatelessWidget {
  const AppStatusView({
    super.key,
    this.leading,
    required this.title,
    this.message,
    this.content = const [],
    this.actions = const [],
  });

  final Widget? leading;
  final String title;
  final String? message;
  final List<Widget> content; // extra content between the message and the actions (e.g. a summary card)
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.m,
              children: [
                if (leading != null) Center(child: leading),
                Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
                if (message != null)
                  Text(message!,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: context.tokens.muted)),
                ...content,
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.s, children: actions),
                  ),
              ],
            ),
          ),
        ),
      );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.icon, required this.title, this.subtitle, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => AppStatusView(
        leading: AppStatusIcon(icon: icon, color: context.tokens.muted),
        title: title,
        message: subtitle,
        actions: [
          if (actionLabel != null && onAction != null) OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, required this.onRetry, this.retryLabel = AppStrings.retry});

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => AppStatusView(
        leading: AppStatusIcon(icon: Icons.error_outline_rounded, color: context.colors.error),
        title: message,
        actions: [
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(retryLabel)),
        ],
      );
}

/// Inline "nothing here yet" row for a section inside a scrolling page: left-aligned, muted icon + text.
class AppEmptyRow extends StatelessWidget {
  const AppEmptyRow({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(spacing: AppSpacing.m, children: [
            Icon(icon, color: context.tokens.muted),
            Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.tokens.muted))),
          ]),
        ),
      );
}
