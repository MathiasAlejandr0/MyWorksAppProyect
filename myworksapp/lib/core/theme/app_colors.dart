import 'package:flutter/material.dart';

/// Colores del Design System — paleta naranjo y blanco.
class AppColors {
  AppColors._();

  // ========== BRAND ==========

  /// Naranjo principal — CTAs, app bar, acentos
  static const Color brandOrange = Color(0xFFF0782A);

  /// Naranjo oscuro — gradientes de encabezado
  static const Color brandOrangeDark = Color(0xFFD9621A);

  /// Azul marino — textos y logo
  static const Color brandNavy = Color(0xFF1A4066);

  /// Fondo suave naranjo
  static const Color brandOrangeSoft = Color(0xFFFFF0E8);

  /// Fondo suave (alias legacy)
  static const Color brandBlueSoft = brandOrangeSoft;

  /// Enlaces y acentos secundarios → naranjo
  static const Color brandTeal = brandOrange;

  // ========== PRIMARY ALIASES (compatibilidad) ==========

  static const Color primaryLight = brandOrange;
  static const Color primaryDark = brandOrangeDark;

  // ========== SECONDARY ==========

  static const Color secondary = brandNavy;

  // ========== SEMANTIC ==========

  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF4C430);
  static const Color info = brandOrange;

  // ========== NEUTRAL ==========

  static const Color white = Color(0xFFFFFFFF);
  static const Color grayLight = Color(0xFFF8F8F8);
  static const Color grayMedium = Color(0xFF9CA3AF);
  static const Color grayDark = Color(0xFF1F2937);
  static const Color black = Color(0xFF000000);

  // ========== BACKGROUND ==========

  static const Color backgroundLight = white;
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceLight = white;
  static const Color surfaceDark = Color(0xFF1F2937);

  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? grayDark : white;
  }

  static Color getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? surfaceDark : surfaceLight;
  }

  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? backgroundDark : backgroundLight;
  }
}
