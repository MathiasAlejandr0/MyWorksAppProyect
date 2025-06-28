import 'package:flutter/material.dart';

class AppColors {
  // Colores principales
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFFBBDEFB);

  // Colores secundarios
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color secondaryDarkColor = Color(0xFFF57C00);
  static const Color secondaryLightColor = Color(0xFFFFE0B2);

  // Colores de estado
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Colores de disponibilidad
  static const Color availableColor = Color(0xFF4CAF50);
  static const Color unavailableColor = Color(0xFFF44336);
  static const Color busyColor = Color(0xFFFF9800);

  // Colores de fondo
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Colores de texto
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textLightColor = Color(0xFFBDBDBD);
  static const Color textOnPrimaryColor = Color(0xFFFFFFFF);

  // Colores de borde
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Colores de sombra
  static const Color shadowColor = Color(0x1F000000);

  // Colores de rating
  static const Color ratingColor = Color(0xFFFFC107);
  static const Color ratingEmptyColor = Color(0xFFE0E0E0);

  // Colores de profesiones
  static const Map<String, Color> professionColors = {
    'Plomero': Color(0xFF2196F3),
    'Electricista': Color(0xFFFF9800),
    'Albañil': Color(0xFF795548),
    'Jardinero': Color(0xFF4CAF50),
    'Cerrajero': Color(0xFF607D8B),
    'Pintor': Color(0xFF9C27B0),
    'Carpintero': Color(0xFF8D6E63),
    'Técnico': Color(0xFF00BCD4),
    'Limpieza': Color(0xFF9E9E9E),
    'Otros': Color(0xFF607D8B),
  };

  // Obtener color por profesión
  static Color getProfessionColor(String profession) {
    return professionColors[profession] ?? professionColors['Otros']!;
  }

  // Obtener color por disponibilidad
  static Color getAvailabilityColor(bool isAvailable) {
    return isAvailable ? availableColor : unavailableColor;
  }

  // Obtener color por rating
  static Color getRatingColor(double rating) {
    if (rating >= 4.0) return successColor;
    if (rating >= 3.0) return warningColor;
    return errorColor;
  }
}
