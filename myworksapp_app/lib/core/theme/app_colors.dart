import 'package:flutter/material.dart';

import 'generated_brand_colors.dart';

/// Sistema de colores del Design System — Inspirado en Apple HIG & Psicología del Color.
///
/// Implementa la regla 60-30-10:
/// - 60% Dominante (Canal neutro y superficies en capas)
/// - 30% Estructura y Confianza (Navy / Slate & Grises Tintados)
/// - 10% Acento (Naranja Energético exclusivo para CTAs y focos activos)
///
/// `brandOrange`, `brandNavy` y `emerald`/`success` salen de
/// [GeneratedBrandColors] (`npm run generate:colors` en shared).
class AppColors {
  AppColors._();

  // ========== BRAND & ACCENT (10% - FOCO DE ACCIÓN) ==========

  /// Naranjo principal vibrante — Exclusivo para CTAs primarios y focos estratégicos
  static const Color brandOrange = GeneratedBrandColors.brandOrange;

  /// Naranjo neón / caliente para gradientes y estados destacados de alta visibilidad
  static const Color brandOrangeVibrant = GeneratedBrandColors.brandOrangeVibrant;

  /// Naranjo oscuro — gradientes y estados pressed
  static const Color brandOrangeDark = Color(0xFFD9530F);

  /// Fondo suave tintado de naranja para badges y selecciones
  static const Color brandOrangeSoft = Color(0x33FF5E03);

  /// Alias legacy
  static const Color brandBlueSoft = brandOrangeSoft;
  static const Color brandTeal = brandOrange;

  // ========== ESTRUCTURA & CONFIANZA (30% - SLATE / NAVY) ==========

  /// Azul marino profundo — aporta seriedad, respaldo de escrow y seguridad
  static const Color brandNavy = GeneratedBrandColors.brandNavy;

  /// Azul Slate intermedio para encabezados secundarios e iconografía estructural
  static const Color brandSlate = Color(0xFF2C3E50);

  // ========== PRIMARY ALIASES (compatibilidad) ==========

  static const Color primaryLight = brandOrange;
  static const Color primaryDark = brandOrangeDark;
  static const Color secondary = brandNavy;

  // ========== APPLE SEMANTIC STATUS (TINTED) ==========

  /// Completado / Verificado — Verde Esmeralda Suave
  static const Color success = GeneratedBrandColors.emerald;
  static const Color successSoft = Color(0x332F9E64);
  static const Color emerald = GeneratedBrandColors.emerald;

  /// Urgente / Error / Cancelado — Coral Carmesí
  static const Color error = GeneratedBrandColors.crimsonError;
  static const Color errorSoft = Color(0x33E23D35);
  static const Color crimson = error;

  /// Pendiente / En Revisión — Ámbar Cálido
  static const Color warning = Color(0xFFC9A227);
  static const Color warningSoft = Color(0x33C9A227);

  static const Color info = Color(0xFF4C8DDB);
  static const Color infoSoft = Color(0x334C8DDB);

  // ========== NEUTRALS & TEXT (60% - CANVAS & TYPOGRAPHY) ==========

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Texto Primario (Apple Dark Label)
  static const Color textPrimary = Color(0xFF1D1D1F);

  /// Texto secundario en superficies claras. En canvas oscuro usar [onCanvasMuted].
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
  static const Color backgroundLight = Color(0xFFF7F5F2);
  static const Color grayBackground = backgroundLight;

  /// Fondo de pantalla en Dark Mode (navy cinematográfico del mockup)
  static const Color backgroundDark = GeneratedBrandColors.bgCanvasDarkAlt;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = GeneratedBrandColors.bgSurfaceDark;
  static const Color surfaceDarkElevated = GeneratedBrandColors.bgElevatedDark;

  // ========== GLASSMORPHISM & TRANSLUCENCY ==========

  /// Fondo esmerilado translucido estilo iOS
  static Color glassBackgroundLight = const Color(0xFFFFFFFF).withValues(alpha: 0.75);
  static Color glassBackgroundDark = GeneratedBrandColors.bgSurfaceDark.withValues(alpha: 0.82);
  static Color glassBorderLight = const Color(0xFFFFFFFF).withValues(alpha: 0.4);
  static Color glassBorderDark = const Color(0xFFFFFFFF).withValues(alpha: 0.12);

  // ========== HELPER METHODS ==========

  /// Texto principal sobre el canvas (fondo de pantalla). Nunca usa grayDark en dark.
  static Color onCanvas(Brightness brightness) {
    return brightness == Brightness.dark ? white : textPrimary;
  }

  /// Título de pantalla: blanco si el canvas es oscuro (tema o luminancia).
  static Color headlineOnScreen(BuildContext context) {
    final theme = Theme.of(context);
    final canvasLuminance = theme.scaffoldBackgroundColor.computeLuminance();
    if (theme.brightness == Brightness.dark || canvasLuminance < 0.4) {
      return white;
    }
    return textPrimary;
  }

  /// Texto secundario con contraste WCAG-AA sobre navy `#0B1424`.
  static Color onCanvasMuted(Brightness brightness) {
    return brightness == Brightness.dark
        ? GeneratedBrandColors.textMutedDark
        : textSecondary;
  }

  /// Iconos decorativos: visibles en dark (naranja ~55%) sin tapar el contenido.
  static Color decorOnCanvas(Brightness brightness, {bool structural = false}) {
    if (brightness == Brightness.dark) {
      return brandOrange.withValues(alpha: 0.55);
    }
    return (structural ? brandNavy : brandOrange).withValues(alpha: 0.38);
  }

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

  /// Superficie elevada según brillo del tema.
  static Color surfaceOf(BuildContext context) {
    return getSurfaceColor(Theme.of(context).brightness == Brightness.dark);
  }

  /// Superficie más elevada (cards secundarias).
  static Color surfaceElevatedOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? surfaceDarkElevated : surfaceLight;
  }

  /// Borde sutil sobre canvas/tarjeta.
  static Color hairlineOf(BuildContext context, {Color? accent}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (accent != null) {
      return accent.withValues(alpha: isDark ? 0.28 : 0.22);
    }
    return isDark
        ? white.withValues(alpha: 0.12)
        : grayBorder.withValues(alpha: 0.9);
  }

  /// Relleno de campo / chip sobre canvas.
  static Color fieldFillOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? white.withValues(alpha: 0.08) : white;
  }
}

