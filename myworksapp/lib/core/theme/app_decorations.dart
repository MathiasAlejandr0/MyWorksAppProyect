import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Decoraciones compartidas del design system MyWorksApp.
class AppDecorations {
  AppDecorations._();

  static const Color screenBackground = AppColors.white;

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.brandOrangeDark,
      AppColors.brandOrange,
      Color(0xFFF5934A),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.white,
      AppColors.brandOrangeSoft,
      Color(0xFFFFFAF7),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static List<BoxShadow> get headerShadow => [
        BoxShadow(
          color: AppColors.brandOrange.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> cardShadow([Color? accent]) => [
        if (accent != null)
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static BoxDecoration surfaceCard({
    Color? accent,
    double radius = 18,
  }) {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (accent ?? AppColors.brandOrange).withValues(alpha: 0.16),
      ),
      boxShadow: cardShadow(accent),
    );
  }

  static BoxDecoration glassPanel({double radius = 16}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.72),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.brandOrange.withValues(alpha: 0.12)),
    );
  }
}
