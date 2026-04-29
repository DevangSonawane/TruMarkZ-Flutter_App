import 'package:flutter/material.dart';

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
        scaffoldBackgroundColor: AppColors.offWhite,
        dividerColor: AppColors.divider,
        textTheme: _buildTextTheme(AppColors.darkNavy),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.offWhite,
          foregroundColor: AppColors.darkNavy,
          elevation: 0,
          centerTitle: false,
          titleTextStyle:
              AppTypography.heading1.copyWith(color: AppColors.darkNavy),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: Colors.white,
            textStyle: AppTypography.button,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
          ),
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
        scaffoldBackgroundColor: AppColors.darkNavy,
        dividerColor: AppColors.divider,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkNavy,
          foregroundColor: AppColors.offWhite,
          elevation: 0,
          centerTitle: false,
          titleTextStyle:
              AppTypography.heading1.copyWith(color: AppColors.offWhite),
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 0,
        ),
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
