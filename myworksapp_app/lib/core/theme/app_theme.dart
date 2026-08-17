import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_elevation.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_spacing.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Tema global — naranjo y blanco en toda la app.
class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge(color: colorScheme.onSurface),
      displayMedium: AppTextStyles.displayMedium(color: colorScheme.onSurface),
      displaySmall: AppTextStyles.displaySmall(color: colorScheme.onSurface),
      headlineLarge: AppTextStyles.headlineLarge(color: colorScheme.onSurface),
      headlineMedium: AppTextStyles.headlineMedium(color: colorScheme.onSurface),
      headlineSmall: AppTextStyles.headlineSmall(color: colorScheme.onSurface),
      titleLarge: AppTextStyles.titleLarge(color: colorScheme.onSurface),
      titleMedium: AppTextStyles.titleMedium(color: colorScheme.onSurface),
      titleSmall: AppTextStyles.titleSmall(color: colorScheme.onSurface),
      bodyLarge: AppTextStyles.bodyLarge(color: colorScheme.onSurface),
      bodyMedium: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
      bodySmall: AppTextStyles.bodySmall(),
      labelLarge: AppTextStyles.labelLarge(color: colorScheme.onSurface),
      labelMedium: AppTextStyles.labelMedium(color: colorScheme.onSurface),
      labelSmall: AppTextStyles.labelSmall(),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brandOrange,
      onPrimary: AppColors.white,
      secondary: AppColors.brandNavy,
      onSecondary: AppColors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.white,
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(textTheme),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandOrange,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.brandNavy,
        titleTextStyle: AppTextStyles.titleLarge(color: AppColors.brandNavy),
        iconTheme: const IconThemeData(color: AppColors.brandNavy),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: AppColors.grayBorder.withValues(alpha: 0.6),
          ),
        ),
        color: AppColors.surfaceLight,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        shadowColor: Colors.black.withValues(alpha: 0.04),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brandOrange,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTextStyles.buttonPrimary(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandOrange,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandOrange,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.brandOrange, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTextStyles.buttonSecondary(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.buttonSecondary(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.grayBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.grayBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brandOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: AppTextStyles.inputLabel(),
        hintStyle: AppTextStyles.inputHint(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandOrange,
        foregroundColor: AppColors.white,
        elevation: AppElevation.level2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.brandOrange,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.brandOrange),
        unselectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.textSecondary),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brandOrange,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.brandOrange,
        dividerColor: AppColors.grayBorder.withValues(alpha: 0.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.brandOrangeSoft,
        selectedColor: AppColors.brandOrange,
        labelStyle: AppTextStyles.titleSmall(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.grayBorder.withValues(alpha: 0.6),
        thickness: 0.5,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.brandNavy,
        contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.success;
          }
          return AppColors.grayBorder;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandOrange;
          return AppColors.grayMedium;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandOrange;
          return AppColors.grayMedium;
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.brandOrange,
      onPrimary: AppColors.white,
      secondary: AppColors.brandNavy,
      onSecondary: AppColors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(textTheme),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandOrange,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.white,
        titleTextStyle: AppTextStyles.titleLarge(color: AppColors.white),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: AppColors.grayBorder.withValues(alpha: 0.15),
          ),
        ),
        color: AppColors.surfaceDark,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
      ),
      elevatedButtonTheme: lightTheme.elevatedButtonTheme,
      filledButtonTheme: lightTheme.filledButtonTheme,
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandOrange,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.brandOrange, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTextStyles.buttonSecondary(color: AppColors.white),
        ),
      ),
      textButtonTheme: lightTheme.textButtonTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.grayBorder.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.grayBorder.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brandOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: AppTextStyles.inputLabel(),
        hintStyle: AppTextStyles.inputHint(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.brandOrange,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brandOrange,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.brandOrange,
        dividerColor: AppColors.grayBorder.withValues(alpha: 0.15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.brandOrange.withValues(alpha: 0.15),
        selectedColor: AppColors.brandOrange,
        labelStyle: AppTextStyles.titleSmall(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.grayBorder.withValues(alpha: 0.15),
        thickness: 0.5,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDarkElevated,
        contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      switchTheme: lightTheme.switchTheme,
      checkboxTheme: lightTheme.checkboxTheme,
      radioTheme: lightTheme.radioTheme,
      floatingActionButtonTheme: lightTheme.floatingActionButtonTheme,
    );
  }

  static EdgeInsets get screenPadding => const EdgeInsets.all(AppSpacing.screenPadding);
  static EdgeInsets get cardPadding => const EdgeInsets.all(AppSpacing.cardPadding);
}

