import 'package:flutter/material.dart';

import '../database/models/service_model.dart';
import 'app_colors.dart';

/// Paleta visual por categoría de servicio.
///
/// Tonos suaves y diferenciados que conviven con la marca naranjo/blanco.
class ServiceCardPalette {
  const ServiceCardPalette({
    required this.background,
    required this.iconBackground,
    required this.accent,
  });

  /// Tinte inferior de la tarjeta.
  final Color background;

  /// Fondo del contenedor del ícono.
  final Color iconBackground;

  /// Ícono, borde sutil y enlace «Solicitar».
  final Color accent;

  static ServiceCardPalette forCategory(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return const ServiceCardPalette(
          background: Color(0xFFFFF4E8),
          iconBackground: Color(0xFFFFE4CC),
          accent: Color(0xFFE07B24),
        );
      case ServiceCategories.plumbing:
        return const ServiceCardPalette(
          background: Color(0xFFEAF6F8),
          iconBackground: Color(0xFFD4EEF2),
          accent: Color(0xFF2A9DAB),
        );
      case ServiceCategories.electrical:
        return const ServiceCardPalette(
          background: Color(0xFFFFF8E6),
          iconBackground: Color(0xFFFFF0C8),
          accent: Color(0xFFD49A12),
        );
      case ServiceCategories.gardening:
        return const ServiceCardPalette(
          background: Color(0xFFEDF6EF),
          iconBackground: Color(0xFFD8EDDF),
          accent: Color(0xFF4D9B6A),
        );
      case ServiceCategories.cleaning:
        return const ServiceCardPalette(
          background: Color(0xFFEDF5FA),
          iconBackground: Color(0xFFD6E8F2),
          accent: Color(0xFF4A90B8),
        );
      case ServiceCategories.assembly:
        return const ServiceCardPalette(
          background: Color(0xFFF7F0E8),
          iconBackground: Color(0xFFEDE0D4),
          accent: Color(0xFFA67B5B),
        );
      case ServiceCategories.techSupport:
        return const ServiceCardPalette(
          background: Color(0xFFEEF2F7),
          iconBackground: Color(0xFFD8E2EC),
          accent: AppColors.brandNavy,
        );
      case ServiceCategories.moving:
        return const ServiceCardPalette(
          background: Color(0xFFF3EEFA),
          iconBackground: Color(0xFFE4DDF2),
          accent: Color(0xFF6B5B95),
        );
      default:
        return const ServiceCardPalette(
          background: AppColors.brandOrangeSoft,
          iconBackground: Color(0xFFFFE4D4),
          accent: AppColors.brandOrange,
        );
    }
  }
}
