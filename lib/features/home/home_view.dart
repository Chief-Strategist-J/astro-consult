import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../astrologer_dashboard/astrologer_dashboard_view.dart';
import '../astrologer_profile/astrologer_profile_view.dart';
import '../astrologers/astrologers_view.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_model.dart';
import '../profile/profile_view.dart';
import '../session/session_view.dart';
import 'home_controller.dart';
import 'home_model.dart';
import 'home_state.dart';

/// Bottom-navigation shell. Users and astrologers get different tabs.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Widget _page(HomeTab tab, bool astrologer) => switch (tab) {
        HomeTab.astrologers => const AstrologersView(),
        HomeTab.history => const HistoryView(),
        HomeTab.dashboard => const AstrologerDashboardView(),
        HomeTab.profile => astrologer ? const AstrologerProfileView() : const ProfileView(),
      };

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user!;
    final astrologer = user.role == UserRole.astrologer;
    return BlocProvider(
      create: (_) => HomeCubit(user.role),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, s) => Scaffold(
          body: IndexedStack(index: s.index, children: [for (final t in s.tabs) _page(t, astrologer)]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: s.index,
            onDestinationSelected: (i) => context.read<HomeCubit>().select(s.tabs[i]),
            destinations: [for (final t in s.tabs) NavigationDestination(icon: Icon(t.icon), label: t.label)],
          ),
        ),
      ),
    );
  }
}
