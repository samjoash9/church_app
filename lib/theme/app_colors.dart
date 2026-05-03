import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.scaffold,
    required this.surface,
    required this.surfaceDim,
    required this.border,
    required this.accent,
    required this.accentSurface,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.drawerBg,
    required this.drawerSelected,
    required this.playingSurface,
    required this.danger,
  });

  final Color scaffold;
  final Color surface;
  final Color surfaceDim;
  final Color border;
  final Color accent;
  final Color accentSurface;
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color drawerBg;
  final Color drawerSelected;
  final Color playingSurface;
  final Color danger;

  static const dark = AppColors(
    scaffold: Color(0xFF1E212B),
    surface: Color(0xFF2A2D39),
    surfaceDim: Color(0xFF232733),
    border: Color(0xFF383C49),
    accent: Color(0xFFAEC4FF),
    accentSurface: Color(0xFFA5BFF2),
    onAccent: Color(0xFF1A1D2B),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFCCD4E8),
    textMuted: Color(0xFF8A94B2),
    drawerBg: Color(0xFF252834),
    drawerSelected: Color(0xFF3D4263),
    playingSurface: Color(0xFF31415F),
    danger: Color(0xFFFF5B5B),
  );

  static const light = AppColors(
    scaffold: Color(0xFFF2F4F8),
    surface: Colors.white,
    surfaceDim: Color(0xFFE8EBF2),
    border: Color(0xFFDDE1EA),
    accent: Color(0xFF4A6CF7),
    accentSurface: Color(0xFF4A6CF7),
    onAccent: Colors.white,
    textPrimary: Color(0xFF1A1D2B),
    textSecondary: Color(0xFF5A6178),
    textMuted: Color(0xFF9AA0B4),
    drawerBg: Color(0xFFF5F6FA),
    drawerSelected: Color(0xFFE1E6F3),
    playingSurface: Color(0xFFDDE5F9),
    danger: Color(0xFFE53E3E),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  @override
  AppColors copyWith({
    Color? scaffold, Color? surface, Color? surfaceDim, Color? border,
    Color? accent, Color? accentSurface, Color? onAccent,
    Color? textPrimary, Color? textSecondary, Color? textMuted,
    Color? drawerBg, Color? drawerSelected, Color? playingSurface, Color? danger,
  }) {
    return AppColors(
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentSurface: accentSurface ?? this.accentSurface,
      onAccent: onAccent ?? this.onAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      drawerBg: drawerBg ?? this.drawerBg,
      drawerSelected: drawerSelected ?? this.drawerSelected,
      playingSurface: playingSurface ?? this.playingSurface,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      drawerBg: Color.lerp(drawerBg, other.drawerBg, t)!,
      drawerSelected: Color.lerp(drawerSelected, other.drawerSelected, t)!,
      playingSurface: Color.lerp(playingSurface, other.playingSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
