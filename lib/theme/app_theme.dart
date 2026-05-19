import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgDeep,
        primary: AppColors.haloPlus,
        secondary: AppColors.haloMinus,
        onPrimary: AppColors.bgVoid,
        onSurface: AppColors.ink,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayXl(),
        displayMedium: AppTypography.displayL(),
        headlineLarge: AppTypography.h1(),
        headlineMedium: AppTypography.h2(),
        titleLarge: AppTypography.cardTitle(),
        bodyLarge: AppTypography.body(size: 15),
        bodyMedium: AppTypography.body(),
        labelLarge: AppTypography.uiButton(),
        labelMedium: AppTypography.eyebrow(),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      dividerColor: AppColors.line,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
