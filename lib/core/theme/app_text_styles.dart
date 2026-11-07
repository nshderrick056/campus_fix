import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography: Fira Sans (H1), Average Sans (H2), Cantarell (body).
///
/// Styles are built from an [AppColors] palette so they work in light and
/// dark mode. In widgets prefer `Theme.of(context).textTheme`.
abstract final class AppTextStyles {
  /// Screen titles, greeting, hero text.
  static TextStyle h1(AppColors c) => GoogleFonts.firaSans(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: c.navy,
        height: 1.2,
      );

  /// Section titles, card titles.
  static TextStyle h2(AppColors c) => GoogleFonts.averageSans(
        fontSize: 20,
        color: c.navy,
        height: 1.25,
      );

  static TextStyle body(AppColors c) => GoogleFonts.cantarell(
        fontSize: 15,
        color: c.navy,
        height: 1.4,
      );

  static TextStyle bodyMuted(AppColors c) =>
      body(c).copyWith(color: c.textMuted);

  /// Buttons, chips, form labels.
  static TextStyle label(AppColors c) => GoogleFonts.cantarell(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: c.navy,
      );

  static TextStyle caption(AppColors c) => GoogleFonts.cantarell(
        fontSize: 12,
        color: c.textMuted,
      );

  /// Material [TextTheme] mapped onto the three families.
  static TextTheme textTheme(AppColors c) {
    final h1 = AppTextStyles.h1(c);
    final h2 = AppTextStyles.h2(c);
    final body = AppTextStyles.body(c);
    final label = AppTextStyles.label(c);
    final caption = AppTextStyles.caption(c);
    return TextTheme(
      displaySmall: h1.copyWith(fontSize: 32),
      headlineMedium: h1.copyWith(fontSize: 28),
      headlineSmall: h1,
      titleLarge: h1.copyWith(fontSize: 22),
      titleMedium: h2,
      titleSmall: h2.copyWith(fontSize: 17),
      bodyLarge: body.copyWith(fontSize: 16),
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: label,
      labelMedium: label.copyWith(fontSize: 13),
      labelSmall: caption.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
