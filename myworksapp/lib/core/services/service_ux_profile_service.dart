import 'package:flutter/material.dart';
import '../database/models/service_model.dart';
import '../theme/app_colors.dart';

/// Perfil UX específico por servicio
///
/// Define:
/// - Icono propio
/// - Color secundario
/// - Texto legal contextual
/// - Advertencias dinámicas
class ServiceUXProfile {
  final String serviceId;
  final IconData icon;
  final Color accentColor;
  final String? warning;
  final String? legalDisclaimer;
  final String? description;

  ServiceUXProfile({
    required this.serviceId,
    required this.icon,
    required this.accentColor,
    this.warning,
    this.legalDisclaimer,
    this.description,
  });
}

/// Servicio para obtener perfiles UX de servicios
class ServiceUXProfileService {
  static final ServiceUXProfileService instance =
      ServiceUXProfileService._();
  ServiceUXProfileService._();

  static const Color _accent = AppColors.brandOrange;
  static const Color _accentDark = AppColors.brandOrangeDark;

  /// Obtiene el perfil UX para un servicio
  ServiceUXProfile getProfile(String serviceId, ServiceModel? service) {
    switch (serviceId.toLowerCase()) {
      case 'support_it':
      case 'tech_support':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.computer,
          accentColor: _accent,
          warning: 'No incluye instalaciones eléctricas certificadas',
          legalDisclaimer: 'Este servicio es de soporte técnico básico. '
              'Para instalaciones eléctricas certificadas, contacta un electricista.',
        );

      case 'electricidad':
      case 'electricista':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.electrical_services,
          accentColor: _accentDark,
          warning: 'Verifica certificaciones para trabajos eléctricos mayores',
          legalDisclaimer: 'Asegúrate de que el trabajador tenga las certificaciones '
              'necesarias para trabajos eléctricos complejos.',
        );

      case 'plomeria':
      case 'plumber':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.plumbing,
          accentColor: _accent,
          warning: 'Trabajos mayores pueden requerir permisos municipales',
        );

      case 'limpieza':
      case 'cleaning':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.cleaning_services,
          accentColor: _accent,
        );

      case 'construccion':
      case 'construction':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.construction,
          accentColor: _accentDark,
          warning: 'Trabajos estructurales requieren permisos y certificaciones',
          legalDisclaimer: 'Trabajos de construcción mayores requieren permisos '
              'municipales y certificaciones profesionales.',
        );

      case 'jardineria':
      case 'gardening':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.local_florist,
          accentColor: _accent,
        );

      case 'montaje':
      case 'assembly':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.build,
          accentColor: _accentDark,
        );

      case 'mudanza':
      case 'moving':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.local_shipping,
          accentColor: _accent,
          warning: 'Verifica seguro de carga para objetos valiosos',
        );

      default:
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.handyman,
          accentColor: _accent,
          legalDisclaimer: service?.legalDisclaimer,
        );
    }
  }

  /// Obtiene el perfil UX basado en el nombre del servicio
  ServiceUXProfile getProfileByName(String serviceName, ServiceModel? service) {
    final normalizedName = serviceName.toLowerCase().trim();

    // Mapeo de nombres comunes a IDs
    if (normalizedName.contains('electric')) return getProfile('electricidad', service);
    if (normalizedName.contains('plom')) return getProfile('plomeria', service);
    if (normalizedName.contains('limp')) return getProfile('limpieza', service);
    if (normalizedName.contains('construc')) return getProfile('construccion', service);
    if (normalizedName.contains('jardin')) return getProfile('jardineria', service);
    if (normalizedName.contains('montaje') || normalizedName.contains('armado')) {
      return getProfile('montaje', service);
    }
    if (normalizedName.contains('mudanza') || normalizedName.contains('traslado')) {
      return getProfile('mudanza', service);
    }
    if (normalizedName.contains('soporte') || normalizedName.contains('técnico') || normalizedName.contains('tecnico')) {
      return getProfile('tech_support', service);
    }

    return getProfile(serviceName, service);
  }
}
