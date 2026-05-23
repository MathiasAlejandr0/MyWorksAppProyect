import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Decoraciones compartidas del design system MyWorksApp.
class AppDecorations {
  AppDecorations._();

  static const Color screenBackground = Color(0xFFF0F4F8);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF061525),
      Color(0xFF0A2540),
      Color(0xFF0F3460),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.9, 1),
    colors: [
      Color(0xFF061525),
      Color(0xFF040E18),
      Color(0xFF071E33),
      Color(0xFF050F1A),
    ],
    stops: [0.0, 0.38, 0.72, 1.0],
  );

  static List<BoxShadow> get headerShadow => [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.28),
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
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static BoxDecoration surfaceCard({
    Color? accent,
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (accent ?? AppColors.primaryLight).withValues(alpha: 0.16),
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
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    );
  }
}
