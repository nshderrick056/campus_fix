import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Shape and spacing tokens.
abstract final class AppSpacing {
  static const screenPadding = 16.0;
  static const cardRadius = 16.0;
  static const controlRadius = 12.0;
}

abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  /// Dark mode: sky-blue primary buttons with dark navy text.
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.iceSoft,
      onPrimaryContainer: c.navy,
      secondary: c.sky,
      onSecondary: c.onPrimary,
      secondaryContainer: c.ice,
      onSecondaryContainer: c.navy,
      surface: c.card,
      onSurface: c.navy,
      onSurfaceVariant: c.textMuted,
      outline: c.border,
      outlineVariant: c.border,
      error: c.error,
      onError: c.onPrimary,
      errorContainer: c.errorBg,
      onErrorContainer: c.error,
    );

    final textTheme = AppTextStyles.textTheme(c);
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final buttonText = textTheme.labelLarge?.copyWith(color: c.onPrimary);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.surface,
      textTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 1,
        shadowColor: c.deep.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: c.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          textStyle: buttonText,
          padding: buttonPadding,
          shape: controlShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          textStyle: buttonText,
          padding: buttonPadding,
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary),
          textStyle: textTheme.labelLarge,
          padding: buttonPadding,
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.body(c).copyWith(color: c.placeholder),
        labelStyle: AppTextStyles.bodyMuted(c),
        border: inputBorder(c.border),
        enabledBorder: inputBorder(c.border),
        focusedBorder: inputBorder(c.sky, 2),
        errorBorder: inputBorder(c.error),
        focusedErrorBorder: inputBorder(c.error, 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.iceSoft,
        selectedColor: c.primary,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: c.onPrimary),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        indicatorColor: c.iceSoft,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.deep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.onHero),
        shape: controlShape,
      ),
    );
  }
}
