import 'package:flutter/material.dart';

import '../../app_constants.dart';
import '../auth/auth_model.dart';

enum HomeTab { astrologers, history, dashboard, profile }

extension HomeTabInfo on HomeTab {
  String get label => switch (this) {
        HomeTab.astrologers => AppStrings.tabAstrologers,
        HomeTab.history => AppStrings.tabHistory,
        HomeTab.dashboard => AppStrings.tabDashboard,
        HomeTab.profile => AppStrings.tabProfile,
      };
  IconData get icon => switch (this) {
        HomeTab.astrologers => Icons.auto_awesome_outlined,
        HomeTab.history => Icons.history,
        HomeTab.dashboard => Icons.dashboard_outlined,
        HomeTab.profile => Icons.person_outline,
      };

  static List<HomeTab> forRole(UserRole role) => switch (role) {
        UserRole.user => const [HomeTab.astrologers, HomeTab.history, HomeTab.profile],
        UserRole.astrologer => const [HomeTab.dashboard, HomeTab.profile],
      };
}
