import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_constants.dart';
import 'theme_controller.dart';
import 'theme_model.dart';

class AppTheme {
  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final isDark = p.brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primary.withValues(alpha: isDark ? 0.24 : 0.12),
      onPrimaryContainer: p.primary,
      secondary: p.secondary,
      onSecondary: Colors.black,
      secondaryContainer: p.primary.withValues(alpha: isDark ? 0.24 : 0.12),
      onSecondaryContainer: p.primary,
      error: p.danger,
      onError: Colors.white,
      errorContainer: p.danger.withValues(alpha: isDark ? 0.24 : 0.12),
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.muted,
      outline: p.outline,
      outlineVariant: p.outline.withValues(alpha: 0.6),
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: isDark ? const Color(0xFF241C38) : const Color(0xFFF3EFF9),
      surfaceContainerHigh: isDark ? const Color(0xFF2B2242) : const Color(0xFFECE6F5),
      surfaceContainerHighest: isDark ? const Color(0xFF33294D) : const Color(0xFFE4DCF0),
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      Typography.material2021().englishLike.apply(
            bodyColor: p.onSurface,
            displayColor: p.onSurface,
          ),
    );
    final textTheme = baseText.copyWith(
      headlineMedium: baseText.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: baseText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: baseText.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: baseText.bodyMedium?.copyWith(height: 1.45),
      bodySmall: baseText.bodySmall?.copyWith(color: p.muted, height: 1.4),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: baseText.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: p.muted),
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.m),
      borderSide: BorderSide(color: p.outline),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: p.onSurface, size: 22),
      extensions: [AppTokens(success: p.success, warning: p.warning, muted: p.muted, outline: p.outline)],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: p.onSurface),
        iconTheme: IconThemeData(color: p.onSurface),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(color: p.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: p.muted),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: p.primary, width: 1.6)),
        errorBorder: border.copyWith(borderSide: BorderSide(color: p.danger)),
        focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: p.danger, width: 1.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          elevation: 0,
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
          foregroundColor: p.onSurface,
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: p.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.primary.withValues(alpha: isDark ? 0.24 : 0.12),
          selectedForegroundColor: p.primary,
          foregroundColor: p.muted,
          side: BorderSide(color: p.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.primary.withValues(alpha: isDark ? 0.25 : 0.14),
        labelStyle: textTheme.labelMedium?.copyWith(color: p.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: p.primary, fontWeight: FontWeight.w600),
        side: BorderSide(color: p.outline),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: p.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? p.primary : p.muted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.primary : p.muted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: p.muted,
        textColor: p.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.surface : p.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: isDark ? p.onSurface : p.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.onPrimary : p.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.outline,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.muted,
        indicatorColor: p.primary,
        dividerColor: p.outline,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? p.surface : p.onSurface,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: isDark ? p.onSurface : p.surface),
      ),
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return IconButton(
      tooltip: AppStrings.toggleTheme,
      icon: Icon(brightness == Brightness.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => context.read<ThemeCubit>().toggle(brightness),
    );
  }
}

/// Circular avatar that falls back to a person icon when there is no photo (e.g. users have none).
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.url, required this.radius});
  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: context.colors.primaryContainer,
        backgroundImage: url.isEmpty ? null : NetworkImage(url),
        child: url.isEmpty ? Icon(Icons.person, size: radius, color: context.colors.primary) : null,
      );
}

/// A titled block of content: the title is left-aligned and all blocks share one gap.
class AppSection extends StatelessWidget {
  const AppSection({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.m,
        children: [Text(title, style: context.text.titleMedium), ...children],
      );
}
