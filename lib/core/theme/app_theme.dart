import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      primary: AppColors.brandBlue,
      onPrimary: Colors.white,
      surface: AppColors.offWhite,
      onSurface: AppColors.darkNavy,
    ),
    scaffoldBackgroundColor: AppColors.pageBg,
    dividerColor: AppColors.divider,
    textTheme: _buildTextTheme(AppColors.darkNavy),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.pageBg,
      foregroundColor: AppColors.darkNavy,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.heading1.copyWith(
        color: AppColors.darkNavy,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
      prefixIconColor: AppColors.textTertiary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        textStyle: AppTypography.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.selected) ? AppColors.brandBlue : null,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.selected) ? AppColors.blueTint : null,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.selected) ? AppColors.brandBlue : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.silverGray.withAlpha(77)),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: Brightness.dark,
      primary: AppColors.brandBlue,
      onPrimary: Colors.white,
      surface: AppColors.darkNavy,
      onSurface: AppColors.offWhite,
    ),
    textTheme: _buildTextTheme(AppColors.offWhite),
    scaffoldBackgroundColor: AppColors.pageBg,
    dividerColor: AppColors.divider,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.pageBg,
      foregroundColor: AppColors.darkNavy,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.heading1.copyWith(
        color: AppColors.darkNavy,
      ),
    ),
    cardTheme: const CardThemeData(color: AppColors.surfaceDark, elevation: 0),
  );

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: AppTypography.display1.copyWith(color: textColor),
      displayMedium: AppTypography.display2.copyWith(color: textColor),
      titleLarge: AppTypography.heading1.copyWith(color: textColor),
      titleMedium: AppTypography.heading2.copyWith(color: textColor),
      bodyLarge: AppTypography.body1.copyWith(color: textColor),
      bodyMedium: AppTypography.body2.copyWith(color: textColor),
      bodySmall: AppTypography.caption.copyWith(color: textColor),
      labelLarge: AppTypography.button.copyWith(color: textColor),
      labelMedium: AppTypography.label.copyWith(color: textColor),
    );
  }
}
