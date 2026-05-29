import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_elevation.dart';
import '../design_system/app_spacing.dart';
import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_text_styles.dart';

/// Design System formal centralizado
/// 
/// Orquesta los colores y estilos de texto para crear los temas
/// de la aplicación (claro y oscuro).
class AppTheme {
  AppTheme._();

  /// Construye el TextTheme usando AppTextStyles
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display (Títulos principales)
      displayLarge: AppTextStyles.displayLarge(color: colorScheme.onSurface),
      displayMedium: AppTextStyles.displayMedium(color: colorScheme.onSurface),
      displaySmall: AppTextStyles.displaySmall(color: colorScheme.onSurface),
      
      // Headlines (Títulos de sección)
      headlineLarge: AppTextStyles.headlineLarge(color: colorScheme.onSurface),
      headlineMedium: AppTextStyles.headlineMedium(color: colorScheme.onSurface),
      headlineSmall: AppTextStyles.headlineSmall(color: colorScheme.onSurface),
      
      // Titles (Subtítulos)
      titleLarge: AppTextStyles.titleLarge(color: colorScheme.onSurface),
      titleMedium: AppTextStyles.titleMedium(color: colorScheme.onSurface),
      titleSmall: AppTextStyles.titleSmall(color: colorScheme.onSurface),
      
      // Body (Texto normal)
      bodyLarge: AppTextStyles.bodyLarge(color: colorScheme.onSurface),
      bodyMedium: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
      bodySmall: AppTextStyles.bodySmall(),
      
      // Labels (Etiquetas)
      labelLarge: AppTextStyles.labelLarge(color: colorScheme.onSurface),
      labelMedium: AppTextStyles.labelMedium(color: colorScheme.onSurface),
      labelSmall: AppTextStyles.labelSmall(),
    );
  }

  // ========== TEMA CLARO ==========
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryLight,
      secondary: AppColors.primaryDark,
      surface: AppColors.white,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.primaryDark,
      onError: AppColors.white,
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppDecorations.screenBackground,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(textTheme),
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        titleTextStyle: AppTextStyles.titleLarge(color: AppColors.white),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.12),
          ),
        ),
        color: AppColors.surfaceLight,
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.08),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonPrimary(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.primaryLight, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonSecondary(),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.buttonSecondary(),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
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
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.inputLabel(),
        hintStyle: AppTextStyles.inputHint(),
      ),

      // Textos (ya definido en _buildTextTheme)

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.white,
        elevation: AppElevation.level2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.grayMedium,
        selectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.primaryLight),
        unselectedLabelStyle: AppTextStyles.labelMedium(color: AppColors.grayMedium),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grayLight,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTextStyles.titleSmall(color: AppColors.primaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.grayMedium.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Modo oscuro
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.primaryLight,
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
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        titleTextStyle: AppTextStyles.titleLarge(color: AppColors.white),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.12),
          ),
        ),
        color: AppColors.surfaceDark,
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonPrimary(),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.primaryLight, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonSecondary(color: AppColors.white),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
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
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        labelStyle: AppTextStyles.inputLabel(),
        hintStyle: AppTextStyles.inputHint(),
      ),

      // Textos
    );
  }
  
  // ========== EXTENSIONES DEL TEMA ==========
  
  /// Obtiene el espaciado estándar del tema
  static EdgeInsets get screenPadding => EdgeInsets.all(AppSpacing.screenPadding);
  
  /// Obtiene el padding de card estándar
  static EdgeInsets get cardPadding => EdgeInsets.all(AppSpacing.cardPadding);
}
