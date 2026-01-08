import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos de texto del Design System
/// 
/// Define todos los estilos tipográficos de la aplicación.
/// Usa fuente del sistema por defecto (SF Pro en iOS, Roboto en Android).
class AppTextStyles {
  AppTextStyles._();

  /// Helper para obtener TextStyle con fuente del sistema
  static TextStyle _getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFamily: null, // Usar fuente del sistema
    );
  }

  // ========== DISPLAY (Títulos principales) ==========
  
  /// Display Large - Títulos principales de pantalla
  static TextStyle displayLarge({Color? color}) => _getTextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.grayDark,
    letterSpacing: -1,
    height: 1.2,
  );
  
  /// Display Medium - Títulos principales medianos
  static TextStyle displayMedium({Color? color}) => _getTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.grayDark,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  /// Display Small - Títulos principales pequeños
  static TextStyle displaySmall({Color? color}) => _getTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.grayDark,
    letterSpacing: -0.5,
    height: 1.3,
  );

  // ========== HEADLINE (Títulos de sección) ==========
  
  /// Headline Large - Títulos de sección grandes
  static TextStyle headlineLarge({Color? color}) => _getTextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.grayDark,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  /// Headline Medium - Títulos de sección medianos
  static TextStyle headlineMedium({Color? color}) => _getTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.grayDark,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  /// Headline Small - Títulos de sección pequeños
  static TextStyle headlineSmall({Color? color}) => _getTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.grayDark,
    height: 1.4,
  );

  // ========== TITLE (Subtítulos) ==========
  
  /// Title Large - Subtítulos grandes
  static TextStyle titleLarge({Color? color}) => _getTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.grayDark,
    height: 1.4,
  );
  
  /// Title Medium - Subtítulos medianos
  static TextStyle titleMedium({Color? color}) => _getTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: color ?? AppColors.grayDark,
    height: 1.4,
  );
  
  /// Title Small - Subtítulos pequeños
  static TextStyle titleSmall({Color? color}) => _getTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? AppColors.grayDark,
    height: 1.4,
  );

  // ========== BODY (Texto normal) ==========
  
  /// Body Large - Texto normal grande
  static TextStyle bodyLarge({Color? color}) => _getTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.grayDark,
    height: 1.5,
  );
  
  /// Body Medium - Texto normal mediano
  static TextStyle bodyMedium({Color? color}) => _getTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.grayDark,
    height: 1.5,
  );
  
  /// Body Small - Texto normal pequeño
  static TextStyle bodySmall({Color? color}) => _getTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.grayMedium,
    height: 1.4,
  );

  // ========== LABEL (Etiquetas) ==========
  
  /// Label Large - Etiquetas grandes
  static TextStyle labelLarge({Color? color}) => _getTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? AppColors.grayDark,
    letterSpacing: 0.1,
  );
  
  /// Label Medium - Etiquetas medianas
  static TextStyle labelMedium({Color? color}) => _getTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color ?? AppColors.grayDark,
    letterSpacing: 0.1,
  );
  
  /// Label Small - Etiquetas pequeñas
  static TextStyle labelSmall({Color? color}) => _getTextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: color ?? AppColors.grayMedium,
    letterSpacing: 0.1,
  );

  // ========== BUTTON STYLES ==========
  
  /// Estilo para botones primarios
  static TextStyle buttonPrimary({Color? color}) => _getTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.white,
    letterSpacing: 0.5,
  );
  
  /// Estilo para botones secundarios
  static TextStyle buttonSecondary({Color? color}) => _getTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.primaryLight,
    letterSpacing: 0.5,
  );

  // ========== INPUT STYLES ==========
  
  /// Estilo para labels de inputs
  static TextStyle inputLabel({Color? color}) => _getTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color ?? AppColors.grayMedium,
  );
  
  /// Estilo para hints de inputs
  static TextStyle inputHint({Color? color}) => _getTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.grayMedium,
  );
}

