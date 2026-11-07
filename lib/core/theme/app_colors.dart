import 'package:flutter/material.dart';

/// CampusFix colour tokens, with a light and a dark palette.
///
/// Registered on [ThemeData.extensions], so widgets read the palette that
/// matches the current brightness:
///
/// ```dart
/// final colors = AppColors.of(context); // or context.colors
/// Icon(Symbols.bolt_rounded, color: colors.primary);
/// ```
///
/// Status colours must always be paired with an icon + label.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.navy,
    required this.primary,
    required this.onPrimary,
    required this.sky,
    required this.ice,
    required this.iceSoft,
    required this.surface,
    required this.card,
    required this.border,
    required this.textMuted,
    required this.placeholder,
    required this.deep,
    required this.onHero,
    required this.submitted,
    required this.submittedBg,
    required this.inProgress,
    required this.inProgressBg,
    required this.resolved,
    required this.resolvedBg,
    required this.error,
    required this.errorBg,
  });

  /// Headings and main text.
  final Color navy;
  final Color primary;
  final Color onPrimary;
  final Color sky;
  final Color ice;
  final Color iceSoft;

  /// Screen background.
  final Color surface;

  /// Cards and inputs.
  final Color card;
  final Color border;
  final Color textMuted;
  final Color placeholder;

  /// Dark hero surfaces (banner gradient start).
  final Color deep;

  /// Text and icons on hero surfaces.
  final Color onHero;

  final Color submitted;
  final Color submittedBg;
  final Color inProgress;
  final Color inProgressBg;
  final Color resolved;
  final Color resolvedBg;
  final Color error;
  final Color errorBg;

  static const light = AppColors(
    navy: Color(0xFF1B365D),
    primary: Color(0xFF005A9C),
    onPrimary: Color(0xFFFFFFFF),
    sky: Color(0xFF60C1E5),
    ice: Color(0xFFA0E0EF),
    iceSoft: Color(0xFFE6F4FA),
    surface: Color(0xFFF6FAFC),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE3EBF2),
    textMuted: Color(0xFF5B6B7F),
    placeholder: Color(0xFF9AA8B8),
    deep: Color(0xFF1B365D),
    onHero: Color(0xFFFFFFFF),
    submitted: Color(0xFFB9771A),
    submittedBg: Color(0xFFFDF1DE),
    inProgress: Color(0xFF005A9C),
    inProgressBg: Color(0xFFE6F4FA),
    resolved: Color(0xFF2E9E6A),
    resolvedBg: Color(0xFFDFF3EA),
    error: Color(0xFFD64545),
    errorBg: Color(0xFFFBE4E4),
  );

  static const dark = AppColors(
    navy: Color(0xFFE6EEF6),
    primary: Color(0xFF60C1E5),
    onPrimary: Color(0xFF0B1A2E),
    sky: Color(0xFF7FD0EC),
    ice: Color(0xFF3B7BA0),
    iceSoft: Color(0xFF13304A),
    surface: Color(0xFF0B1622),
    card: Color(0xFF13202E),
    border: Color(0xFF24364A),
    textMuted: Color(0xFF9AB0C4),
    placeholder: Color(0xFF6C8297),
    deep: Color(0xFF08121D),
    onHero: Color(0xFFFFFFFF),
    submitted: Color(0xFFF2B95B),
    submittedBg: Color(0xFF3A2C14),
    inProgress: Color(0xFF60C1E5),
    inProgressBg: Color(0xFF12324A),
    resolved: Color(0xFF4CC38A),
    resolvedBg: Color(0xFF123526),
    error: Color(0xFFF07070),
    errorBg: Color(0xFF3B1A1C),
  );

  /// The palette for the current theme (falls back to [light]).
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? navy,
    Color? primary,
    Color? onPrimary,
    Color? sky,
    Color? ice,
    Color? iceSoft,
    Color? surface,
    Color? card,
    Color? border,
    Color? textMuted,
    Color? placeholder,
    Color? deep,
    Color? onHero,
    Color? submitted,
    Color? submittedBg,
    Color? inProgress,
    Color? inProgressBg,
    Color? resolved,
    Color? resolvedBg,
    Color? error,
    Color? errorBg,
  }) {
    return AppColors(
      navy: navy ?? this.navy,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      sky: sky ?? this.sky,
      ice: ice ?? this.ice,
      iceSoft: iceSoft ?? this.iceSoft,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      textMuted: textMuted ?? this.textMuted,
      placeholder: placeholder ?? this.placeholder,
      deep: deep ?? this.deep,
      onHero: onHero ?? this.onHero,
      submitted: submitted ?? this.submitted,
      submittedBg: submittedBg ?? this.submittedBg,
      inProgress: inProgress ?? this.inProgress,
      inProgressBg: inProgressBg ?? this.inProgressBg,
      resolved: resolved ?? this.resolved,
      resolvedBg: resolvedBg ?? this.resolvedBg,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      navy: l(navy, other.navy),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      sky: l(sky, other.sky),
      ice: l(ice, other.ice),
      iceSoft: l(iceSoft, other.iceSoft),
      surface: l(surface, other.surface),
      card: l(card, other.card),
      border: l(border, other.border),
      textMuted: l(textMuted, other.textMuted),
      placeholder: l(placeholder, other.placeholder),
      deep: l(deep, other.deep),
      onHero: l(onHero, other.onHero),
      submitted: l(submitted, other.submitted),
      submittedBg: l(submittedBg, other.submittedBg),
      inProgress: l(inProgress, other.inProgress),
      inProgressBg: l(inProgressBg, other.inProgressBg),
      resolved: l(resolved, other.resolved),
      resolvedBg: l(resolvedBg, other.resolvedBg),
      error: l(error, other.error),
      errorBg: l(errorBg, other.errorBg),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => AppColors.of(this);
}
