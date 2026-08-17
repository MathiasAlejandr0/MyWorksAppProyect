import 'package:flutter/material.dart';

/// Sistema de colores del Design System — Inspirado en Apple HIG & Psicología del Color.
///
/// Implementa la regla 60-30-10:
/// - 60% Dominante (Canal neutro y superficies en capas)
/// - 30% Estructura y Confianza (Navy / Slate & Grises Tintados)
/// - 10% Acento (Naranja Energético exclusivo para CTAs y focos activos)
class AppColors {
  AppColors._();

  // ========== BRAND & ACCENT (10% - FOCO DE ACCIÓN) ==========

  /// Naranjo principal vibrante — Exclusivo para CTAs primarios y focos estratégicos
  static const Color brandOrange = Color(0xFFF0782A);

  /// Naranjo neón / caliente para gradientes y estados destacados de alta visibilidad
  static const Color brandOrangeVibrant = Color(0xFFFF6B00);

  /// Naranjo oscuro — gradientes y estados pressed
  static const Color brandOrangeDark = Color(0xFFD9530F);

  /// Fondo suave tintado de naranja para badges y selecciones
  static const Color brandOrangeSoft = Color(0xFFFFF4EE);

  /// Alias legacy
  static const Color brandBlueSoft = brandOrangeSoft;
  static const Color brandTeal = brandOrange;

  // ========== ESTRUCTURA & CONFIANZA (30% - SLATE / NAVY) ==========

  /// Azul marino profundo — aporta seriedad, respaldo de escrow y seguridad
  static const Color brandNavy = Color(0xFF1A2536);

  /// Azul Slate intermedio para encabezados secundarios e iconografía estructural
  static const Color brandSlate = Color(0xFF2C3E50);

  // ========== PRIMARY ALIASES (compatibilidad) ==========

  static const Color primaryLight = brandOrange;
  static const Color primaryDark = brandOrangeDark;
  static const Color secondary = brandNavy;

  // ========== APPLE SEMANTIC STATUS (TINTED) ==========

  /// Completado / Verificado — Verde Esmeralda Suave
  static const Color success = Color(0xFF34C759);
  static const Color successSoft = Color(0xFFE8F8EE);
  static const Color emerald = success;

  /// Urgente / Error / Cancelado — Coral Carmesí
  static const Color error = Color(0xFFFF3B30);
  static const Color errorSoft = Color(0xFFFFEBEA);
  static const Color crimson = error;

  /// Pendiente / En Revisión — Ámbar Cálido
  static const Color warning = Color(0xFFFF9500);
  static const Color warningSoft = Color(0xFFFFF5E6);

  /// En Proceso / Técnico — Azul Cobalto Vivo
  static const Color info = Color(0xFF007AFF);
  static const Color infoSoft = Color(0xFFE5F1FF);

  // ========== NEUTRALS & TEXT (60% - CANVAS & TYPOGRAPHY) ==========

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Texto Primario (Apple Dark Label)
  static const Color textPrimary = Color(0xFF1D1D1F);

  /// Texto Secundario (Apple Muted Secondary Label)
  static const Color textSecondary = Color(0xFF8E8E93);

  /// Texto Terciario / Deshabilitado
  static const Color textTertiary = Color(0xFFC7C7CC);

  /// Grises neutros tintados estilo Apple
  static const Color grayLight = Color(0xFFF2F2F7);
  static const Color grayMedium = Color(0xFF8E8E93);
  static const Color grayDark = Color(0xFF1C1C1E);
  static const Color grayBorder = Color(0xFFE5E5EA);

  // ========== APPLE SYSTEM BACKGROUNDS (LAYERS) ==========

  /// Fondo de pantalla principal (Light: Apple System Grouped Background)
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color grayBackground = backgroundLight;

  /// Fondo de pantalla en Dark Mode (True Deep Black iOS)
  static const Color backgroundDark = Color(0xFF000000);

  /// Superficie de tarjetas elevadas (Light)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Superficie de tarjetas elevadas (Dark - Apple Grouped Cell)
  static const Color surfaceDark = Color(0xFF1C1C1E);

  /// Superficie secundaria para elevaciones superiores en Dark Mode
  static const Color surfaceDarkElevated = Color(0xFF2C2C2E);

  // ========== GLASSMORPHISM & TRANSLUCENCY ==========

  /// Fondo esmerilado translucido estilo iOS
  static Color glassBackgroundLight = const Color(0xFFFFFFFF).withValues(alpha: 0.75);
  static Color glassBackgroundDark = const Color(0xFF1C1C1E).withValues(alpha: 0.75);
  static Color glassBorderLight = const Color(0xFFFFFFFF).withValues(alpha: 0.4);
  static Color glassBorderDark = const Color(0xFFFFFFFF).withValues(alpha: 0.12);

  // ========== HELPER METHODS ==========

  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : white;
  }

  static Color getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? surfaceDark : surfaceLight;
  }

  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? backgroundDark : backgroundLight;
  }
}

