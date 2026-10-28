import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    // Prompt for Display & Headings, Sarabun for Body
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.prompt(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.onSurface,
      ),
      displayMedium: GoogleFonts.prompt(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.28,
        color: AppColors.onSurface,
      ),
      titleLarge: GoogleFonts.prompt(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.30,
        color: AppColors.onSurface,
      ),
      titleMedium: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.onSurface,
      ),
      bodyLarge: GoogleFonts.sarabun(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.60,
        color: AppColors.onSurface,
      ),
      bodyMedium: GoogleFonts.sarabun(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.60,
        color: AppColors.onSurface,
      ),
      bodySmall: GoogleFonts.sarabun(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: AppColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.prompt(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.40,
        color: AppColors.onSurface,
      ),
      labelMedium: GoogleFonts.prompt(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.40,
        color: AppColors.onSurface,
      ),
      labelSmall: GoogleFonts.prompt(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(
            color: AppColors.surfaceContainerHighest,
            width: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainer,
        indicatorColor: AppColors.primaryContainer,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          );
        }),
      ),
    );
  }
}
