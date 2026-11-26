import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_constants.dart';
import '../auth/auth_controller.dart';
import '../theme/theme_model.dart';
import '../theme/theme_view.dart';
import 'astrologer_profile_controller.dart';
import 'astrologer_profile_state.dart';

/// Astrologer profile editor. With [setup] = true it is the mandatory first-run screen.
class AstrologerProfileView extends StatelessWidget {
  const AstrologerProfileView({super.key, this.setup = false, @visibleForTesting this.previewCubit});
  final bool setup;
  final AstrologerProfileCubit? previewCubit;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>();
    return BlocProvider(
      create: (_) => previewCubit ?? AstrologerProfileCubit(auth, auth.state.user!),
      child: BlocConsumer<AstrologerProfileCubit, AstrologerProfileState>(
        listenWhen: (a, b) => a.error != b.error && b.error != null || a.saves != b.saves,
        listener: (context, s) {
          final m = ScaffoldMessenger.of(context);
          if (s.error != null) m.showSnackBar(SnackBar(content: Text(s.error!)));
          if (s.saves > 0 && s.error == null) m.showSnackBar(const SnackBar(content: Text(AppStrings.profileSaved)));
        },
        builder: (context, s) {
          final c = context.read<AstrologerProfileCubit>();
          return Scaffold(
            appBar: AppBar(
              title: Text(setup ? AppStrings.astroProfileSetupTitle : AppStrings.astroProfileTitle),
              actions: const [ThemeToggleButton()],
            ),
            body: SafeArea(
              child: s.loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      child: Column(
                        spacing: AppSpacing.m,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(AppStrings.astroProfileHint,
                              style: context.text.bodyMedium?.copyWith(color: context.tokens.muted)),
                          TextFormField(
                            initialValue: s.name,
                            onChanged: c.setName,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(labelText: AppStrings.fullName, errorText: s.nameError),
                          ),
                          TextFormField(
                            initialValue: s.avatar,
                            onChanged: c.setAvatar,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(labelText: AppStrings.fieldAvatar, errorText: s.avatarError),
                          ),
                          TextFormField(
                            initialValue: s.expertise,
                            onChanged: c.setExpertise,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(labelText: AppStrings.fieldExpertise, errorText: s.expertiseError),
                          ),
                          TextFormField(
                            initialValue: s.languages,
                            onChanged: c.setLanguages,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(labelText: AppStrings.fieldLanguages, errorText: s.languagesError),
                          ),
                          TextFormField(
                            initialValue: s.experience,
                            onChanged: c.setExperience,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(labelText: AppStrings.fieldExperience, errorText: s.experienceError),
                          ),
                          TextFormField(
                            initialValue: s.price,
                            onChanged: c.setPrice,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: AppStrings.fieldPrice, errorText: s.priceError),
                          ),
                          TextFormField(
                            initialValue: s.about,
                            onChanged: c.setAbout,
                            minLines: 3,
                            maxLines: 6,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(labelText: AppStrings.fieldAbout, errorText: s.aboutError),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s),
                            child: FilledButton(
                              onPressed: s.saving ? null : c.save,
                              child: Text(s.saving
                                  ? AppStrings.pleaseWait
                                  : (setup ? AppStrings.saveContinue : AppStrings.saveChanges)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: context.read<AuthCubit>().logout,
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
