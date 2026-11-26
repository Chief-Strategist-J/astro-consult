import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'profile_controller.dart';
import 'profile_state.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, this.setup = false});
  final bool setup;

  Future<void> _pickDate(BuildContext context, ProfileCubit cubit, ProfileState s) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(s.dob) ?? DateTime(now.year - AppConfig.defaultBirthYearsAgo),
      firstDate: DateTime(AppConfig.earliestBirthYear),
      lastDate: now,
    );
    if (d != null) cubit.setDob(DateFormat(AppConfig.dateFormat).format(d));
  }

  Future<void> _pickTime(BuildContext context, ProfileCubit cubit) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: AppConfig.defaultBirthHour, minute: 0),
    );
    if (t == null) return;
    String two(int n) => n.toString().padLeft(2, AppConfig.padChar);
    cubit.setBirthTime(AppConfig.clockTime(two(t.hour), two(t.minute)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>();
    return BlocProvider(
      create: (_) => ProfileCubit(auth, auth.state.user!),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (a, b) => a.error != b.error && b.error != null || a.saves != b.saves,
        listener: (context, s) {
          final m = ScaffoldMessenger.of(context);
          if (s.error != null) m.showSnackBar(SnackBar(content: Text(s.error!)));
          if (s.saves > 0 && s.error == null) {
            m.showSnackBar(const SnackBar(content: Text(AppStrings.profileSaved)));
          }
        },
        builder: (context, s) {
          final c = context.read<ProfileCubit>();
          final user = context.watch<AuthCubit>().state.user!;
          return Scaffold(
            appBar: AppBar(
              title: Text(setup ? AppStrings.profileSetupTitle : AppStrings.profileTitle),
              actions: const [ThemeToggleButton()],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Column(
                  spacing: AppSpacing.m,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (setup)
                      Text(AppStrings.profileSetupHint,
                          style: context.text.bodyMedium?.copyWith(color: context.tokens.muted)),
                    TextFormField(
                      initialValue: s.name,
                      onChanged: c.setName,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: AppStrings.fullName, errorText: s.nameError),
                    ),
                    TextFormField(
                      initialValue: user.phone,
                      enabled: false,
                      decoration: const InputDecoration(labelText: AppStrings.mobileNumber),
                    ),
                    TextFormField(
                      key: ValueKey('dob-${s.dob}'),
                      initialValue: s.dob,
                      readOnly: true,
                      onTap: () => _pickDate(context, c, s),
                      decoration: InputDecoration(
                        labelText: AppStrings.dob,
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        errorText: s.dobError,
                      ),
                    ),
                    TextFormField(
                      key: ValueKey('time-${s.birthTime}'),
                      initialValue: s.birthTime,
                      readOnly: true,
                      onTap: () => _pickTime(context, c),
                      decoration: InputDecoration(
                        labelText: AppStrings.birthTime,
                        suffixIcon: const Icon(Icons.access_time),
                        errorText: s.timeError,
                      ),
                    ),
                    TextFormField(
                      initialValue: s.birthPlace,
                      onChanged: c.setBirthPlace,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppStrings.birthPlace,
                        suffixIcon: const Icon(Icons.place_outlined),
                        errorText: s.placeError,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s),
                      child: FilledButton(
                        onPressed: s.saving ? null : c.save,
                        child: s.saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(setup ? AppStrings.saveContinue : AppStrings.saveChanges),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: auth.logout,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.colors.error.withValues(alpha: 0.4)),
                      ),
                      icon: Icon(Icons.logout, color: context.colors.error),
                      label: Text(AppStrings.logOut, style: TextStyle(color: context.colors.error)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
