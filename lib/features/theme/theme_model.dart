import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4, s = 8, m = 16, l = 24, xl = 32;

  /// Every page uses the same outer gutter and the same gap between its sections.
  static const double page = m, section = l;
}

class AppRadius {
  static const double s = 8, m = 14, l = 24;
}

class AppPalette {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.outline,
    required this.success,
    required this.warning,
    required this.danger,
    required this.brightness,
  });

  final Color primary, onPrimary, secondary, background, surface, onSurface;
  final Color muted, outline, success, warning, danger;
  final Brightness brightness;

  static const light = AppPalette(
    primary: Color(0xFF5B2A86),
    onPrimary: Colors.white,
    secondary: Color(0xFFF4A300),
    background: Color(0xFFF7F4FB),
    surface: Colors.white,
    onSurface: Color(0xFF1C1428),
    muted: Color(0xFF6E6580),
    outline: Color(0xFFE2DAEE),
    success: Color(0xFF1E9E5A),
    warning: Color(0xFFE08A00),
    danger: Color(0xFFD32F2F),
    brightness: Brightness.light,
  );

  static const dark = AppPalette(
    primary: Color(0xFFC9A6F2),
    onPrimary: Color(0xFF2A1048),
    secondary: Color(0xFFFFC857),
    background: Color(0xFF130E1C),
    surface: Color(0xFF1E1730),
    onSurface: Color(0xFFEDE7F6),
    muted: Color(0xFFA69BB8),
    outline: Color(0xFF3A2F52),
    success: Color(0xFF4CD08A),
    warning: Color(0xFFFFB74D),
    danger: Color(0xFFFF6B6B),
    brightness: Brightness.dark,
  );
}

class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({required this.success, required this.warning, required this.muted, required this.outline});
  final Color success, warning, muted, outline;

  @override
  AppTokens copyWith({Color? success, Color? warning, Color? muted, Color? outline}) => AppTokens(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        muted: muted ?? this.muted,
        outline: outline ?? this.outline,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
