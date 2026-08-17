import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Decoraciones compartidas del design system MyWorksApp estilo Apple HIG.
class AppDecorations {
  AppDecorations._();

  /// Fondo de pantalla principal (Apple System Grouped Background)
  static const Color screenBackground = AppColors.backgroundLight;

  /// Gradiente sutil de encabezados premium (Navy & Slate a Naranja Acción)
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.brandNavy,
      AppColors.brandSlate,
    ],
  );

  /// Gradiente exclusivo para botones o tarjetas VIP
  static const LinearGradient heroAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.brandOrangeVibrant,
      AppColors.brandOrange,
    ],
  );

  /// Gradiente de bienvenida con difusión ambiental suave
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.backgroundLight,
      AppColors.brandOrangeSoft,
      AppColors.white,
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// Sombras compuestas estilo iOS (Difusa ambiente + proyectada sutil)
  static List<BoxShadow> appleCardShadow({Color? accent, bool isDark = false}) => [
        BoxShadow(
          color: (accent ?? Colors.black).withValues(alpha: isDark ? 0.3 : 0.04),
          blurRadius: 18,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: (accent ?? Colors.black).withValues(alpha: isDark ? 0.2 : 0.02),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  /// Alias de sombras por compatibilidad
  static List<BoxShadow> get headerShadow => appleCardShadow(accent: AppColors.brandNavy);
  static List<BoxShadow> cardShadow([Color? accent]) => appleCardShadow(accent: accent);

  /// Tarjeta de superficie elevada estilo Apple (Light/Dark aware)
  static BoxDecoration surfaceCard({
    Color? accent,
    double radius = 20,
    bool isDark = false,
    Color? overrideColor,
  }) {
    final bgColor = overrideColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final borderColor = isDark
        ? AppColors.grayBorder.withValues(alpha: 0.12)
        : (accent != null
            ? accent.withValues(alpha: 0.2)
            : AppColors.grayBorder.withValues(alpha: 0.6));

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
      boxShadow: appleCardShadow(accent: accent, isDark: isDark),
    );
  }

  /// Panel esmerilado / Glassmorphic translucido estilo iOS
  static BoxDecoration glassPanel({
    double radius = 20,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.glassBackgroundDark : AppColors.glassBackgroundLight,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        width: 1,
      ),
      boxShadow: appleCardShadow(isDark: isDark),
    );
  }
}

