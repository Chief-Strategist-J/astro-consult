import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'auth_controller.dart';
import 'auth_model.dart';
import 'auth_state.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (a, b) => a.error != b.error && b.error != null,
      listener: (context, s) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
      builder: (context, s) {
        final c = context.read<AuthCubit>();
        final otpStep = s.status == AuthStatus.otpPending;
        return Scaffold(
          appBar: AppBar(actions: const [ThemeToggleButton()]),
          body: SafeArea(
            // Top-aligned (not vertically centred) so the logo, selector and title never jump between modes.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xl, AppSpacing.page, AppSpacing.page),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    spacing: AppSpacing.m,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.auto_awesome, size: 56, color: context.colors.primary),
                      SegmentedButton<UserRole>(
                        showSelectedIcon: false,
                        segments: [
                          for (final r in UserRole.values) ButtonSegment(value: r, label: Text(r.label)),
                        ],
                        selected: {s.role},
                        onSelectionChanged: s.loading || otpStep ? null : (v) => c.setRole(v.first),
                      ),
                      Text(
                        otpStep ? AppStrings.otpTitle : _title(s),
                        style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        otpStep
                            ? AppStrings.otpSubtitle(s.phone)
                            : (s.role == UserRole.astrologer ? AppStrings.authSubtitleAstrologer : AppStrings.authSubtitle),
                        style: context.text.bodyMedium?.copyWith(color: context.tokens.muted),
                        textAlign: TextAlign.center,
                      ),
                      ...(otpStep ? _otpFields(context, s, c) : _credentialFields(context, s, c)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _title(AuthState s) => switch ((s.role, s.isSignUp)) {
        (UserRole.user, false) => AppStrings.loginTitle,
        (UserRole.user, true) => AppStrings.signUpTitle,
        (UserRole.astrologer, false) => AppStrings.loginTitleAstrologer,
        (UserRole.astrologer, true) => AppStrings.signUpTitleAstrologer,
      };

  List<Widget> _credentialFields(BuildContext context, AuthState s, AuthCubit c) => [
        if (s.isSignUp)
          TextFormField(
            key: ValueKey('name-${s.epoch}'),
            initialValue: s.name,
            onChanged: c.setName,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: AppStrings.fullName,
              prefixIcon: const Icon(Icons.person_outline),
              errorText: s.nameError,
            ),
          ),
        TextFormField(
          key: ValueKey('phone-${s.epoch}'),
          initialValue: s.phone,
          onChanged: c.setPhone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppConfig.phoneLength),
          ],
          decoration: InputDecoration(
            labelText: AppStrings.mobileNumber,
            prefixText: AppStrings.phonePrefix,
            prefixIcon: const Icon(Icons.phone_outlined),
            errorText: s.phoneError,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s),
          child: FilledButton(
            onPressed: s.loading ? null : c.sendOtp,
            child: Text(s.loading ? AppStrings.pleaseWait : (s.isSignUp ? AppStrings.signUp : AppStrings.sendOtp)),
          ),
        ),
        TextButton(
          onPressed: s.loading ? null : c.toggleMode,
          child: Text(s.isSignUp ? AppStrings.toLogin : AppStrings.toSignUp),
        ),
      ];

  List<Widget> _otpFields(BuildContext context, AuthState s, AuthCubit c) => [
        TextFormField(
          key: ValueKey('otp-${s.epoch}'),
          initialValue: s.otp,
          onChanged: c.setOtp,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall?.copyWith(letterSpacing: AppSpacing.s),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppConfig.otpLength),
          ],
          decoration: InputDecoration(hintText: AppStrings.otpHint, errorText: s.otpError),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s),
          child: FilledButton(
            onPressed: s.loading ? null : c.verifyOtp,
            child: Text(s.loading ? AppStrings.pleaseWait : AppStrings.verifyContinue),
          ),
        ),
        Wrap(alignment: WrapAlignment.center, children: [
          TextButton(
            onPressed: s.loading ? null : () => c.sendOtp(resend: true),
            child: const Text(AppStrings.resendOtp),
          ),
          TextButton(onPressed: s.loading ? null : c.backToLogin, child: const Text(AppStrings.changeNumber)),
        ]),
      ];
}
