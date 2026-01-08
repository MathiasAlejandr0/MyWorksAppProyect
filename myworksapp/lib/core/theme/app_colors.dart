import 'package:flutter/material.dart';

/// Colores del Design System
/// 
/// Define todos los colores de la aplicación de forma centralizada.
/// Sigue Material Design 3 y principios de accesibilidad.
class AppColors {
  AppColors._();

  // ========== PRIMARY COLORS ==========
  
  /// Azul oscuro - Color primario principal
  static const Color primaryDark = Color(0xFF0A2540);
  
  /// Azul claro - Color primario secundario
  static const Color primaryLight = Color(0xFF3DA9FC);
  
  // ========== SECONDARY COLORS ==========
  
  /// Índigo - Color secundario
  static const Color secondary = Color(0xFF6366F1);
  
  // ========== SEMANTIC COLORS ==========
  
  /// Verde - Éxito, confirmación
  static const Color success = Color(0xFF2ECC71);
  
  /// Rojo - Error, peligro
  static const Color error = Color(0xFFE74C3C);
  
  /// Amarillo suave - Advertencia
  static const Color warning = Color(0xFFF4C430);
  
  /// Azul info - Información
  static const Color info = Color(0xFF3DA9FC);
  
  // ========== NEUTRAL COLORS ==========
  
  /// Blanco puro
  static const Color white = Color(0xFFFFFFFF);
  
  /// Gris claro - Backgrounds claros
  static const Color grayLight = Color(0xFFF2F2F2);
  
  /// Gris medio - Textos secundarios, bordes
  static const Color grayMedium = Color(0xFF9CA3AF);
  
  /// Gris oscuro - Textos principales
  static const Color grayDark = Color(0xFF1F2937);
  
  /// Negro puro
  static const Color black = Color(0xFF000000);
  
  // ========== BACKGROUND COLORS ==========
  
  /// Background claro (modo claro)
  static const Color backgroundLight = grayLight;
  
  /// Background oscuro (modo oscuro)
  static const Color backgroundDark = Color(0xFF111827);
  
  /// Surface claro (modo claro)
  static const Color surfaceLight = white;
  
  /// Surface oscuro (modo oscuro)
  static const Color surfaceDark = Color(0xFF1F2937);
  
  // ========== HELPER METHODS ==========
  
  /// Obtiene el color de texto apropiado según el fondo
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calcular luminosidad relativa
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? grayDark : white;
  }
  
  /// Obtiene el color de superficie según el modo
  static Color getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? surfaceDark : surfaceLight;
  }
  
  /// Obtiene el color de fondo según el modo
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? backgroundDark : backgroundLight;
  }
}

