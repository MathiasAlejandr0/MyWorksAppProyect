import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_elevation.dart';
import '../design_system/app_spacing.dart';
import 'app_colors.dart';
import 'app_decorations.dart';
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
    final colorScheme = ColorScheme.light(
      primary: AppColors.brandOrange,
      onPrimary: AppColors.white,
      secondary: AppColors.brandNavy,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.grayDark,
      error: AppColors.error,
      onError: AppColors.white,
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDecorations.screenBackground,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(textTheme),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandOrange,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        backgroundColor: AppColors.brandOrange,
        foregroundColor: AppColors.white,
        titleTextStyle: AppTextStyles.titleLarge(color: AppColors.white),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.brandOrange.withValues(alpha: 0.12),
          ),
        ),
        color: AppColors.white,
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        shadowColor: AppColors.brandOrange.withValues(alpha: 0.08),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.brandOrange,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
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
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandOrange,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.brandOrange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
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
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg + AppSpacing.xs,
          vertical: AppSpacing.lg + AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brandOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.inputLabel(),
        hintStyle: AppTextStyles.inputHint(),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandOrange,
        foregroundColor: AppColors.white,
        elevation: AppElevation.level2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.brandOrange,
        unselectedItemColor: AppColors.grayMedium,
        selectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.brandOrange),
        unselectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.grayMedium),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brandOrange,
        unselectedLabelColor: AppColors.grayMedium,
        indicatorColor: AppColors.brandOrange,
        dividerColor: AppColors.grayMedium.withValues(alpha: 0.15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.brandOrangeSoft,
        selectedColor: AppColors.brandOrange,
        labelStyle: AppTextStyles.titleSmall(color: AppColors.grayDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.grayMedium.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.brandNavy,
        contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandOrange;
          return AppColors.grayMedium;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandOrange.withValues(alpha: 0.35);
          }
          return AppColors.grayLight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brandOrange;
          return AppColors.grayMedium;
        }),
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
    final colorScheme = ColorScheme.dark(
      primary: AppColors.brandOrange,
      secondary: AppColors.brandOrange,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
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
        backgroundColor: AppColors.brandOrangeDark,
        foregroundColor: AppColors.white,
        titleTextStyle: AppTextStyles.titleLarge(color: AppColors.white),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      elevatedButtonTheme: lightTheme.elevatedButtonTheme,
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandOrange,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.brandOrange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: AppTextStyles.buttonSecondary(color: AppColors.white),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brandOrange, width: 2),
        ),
        labelStyle: AppTextStyles.inputLabel(),
        hintStyle: AppTextStyles.inputHint(),
      ),
    );
  }

  static EdgeInsets get screenPadding => EdgeInsets.all(AppSpacing.screenPadding);
  static EdgeInsets get cardPadding => EdgeInsets.all(AppSpacing.cardPadding);
}
