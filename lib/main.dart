import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_constants.dart';
import 'features/astrologers/astrologers_controller.dart';
import 'features/astrologer_profile/astrologer_profile_view.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_model.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/auth_view.dart';
import 'features/home/home_view.dart';
import 'features/profile/profile_view.dart';
import 'features/session/session_controller.dart';
import 'features/theme/theme_controller.dart';
import 'features/theme/theme_state.dart';
import 'features/theme/theme_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // config comes from google-services.json / GoogleService-Info.plist (not in git)
  runApp(const AstroApp());
}

class AstroApp extends StatelessWidget {
  const AstroApp({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()..load()),
          BlocProvider(create: (_) => AuthCubit()..restore()),
          BlocProvider(create: (_) => SessionCubit()),
          BlocProvider(create: (_) => AstrologersCubit()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, theme) => MaterialApp(
            title: AppStrings.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.mode,
            home: const _AuthGate(),
          ),
        ),
      );
}

/// Routes between splash, auth, first-run profile and the main app.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, s) {
        if (s.status == AuthStatus.authenticated) {
          // Users browse the catalogue and see their own history; astrologers use their dashboard instead.
          if (s.user?.role == UserRole.user) {
            context.read<AstrologersCubit>().load();
            context.read<SessionCubit>().loadHistory();
          }
        } else if (s.status == AuthStatus.unauthenticated) {
          context.read<SessionCubit>().clearHistory();
          Navigator.of(context).popUntil((r) => r.isFirst); // leave any pushed screens after logout
        }
      },
      builder: (context, s) => switch (s.status) {
        AuthStatus.initial => const Scaffold(body: Center(child: CircularProgressIndicator())),
        AuthStatus.unauthenticated || AuthStatus.otpPending => const AuthView(),
        AuthStatus.authenticated => switch (s.user!.role) {
            UserRole.user => s.user!.isProfileComplete ? const HomeView() : const ProfileView(setup: true),
            UserRole.astrologer => s.astrologerReady ? const HomeView() : const AstrologerProfileView(setup: true),
          },
      },
    );
  }
}
