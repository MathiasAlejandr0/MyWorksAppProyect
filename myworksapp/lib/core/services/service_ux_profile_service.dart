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

  /// Obtiene el perfil UX para un servicio
  ServiceUXProfile getProfile(String serviceId, ServiceModel? service) {
    // Perfiles predefinidos por servicio
    switch (serviceId.toLowerCase()) {
      case 'support_it':
      case 'tech_support':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.computer,
          accentColor: Colors.blueGrey,
          warning: 'No incluye instalaciones eléctricas certificadas',
          legalDisclaimer: 'Este servicio es de soporte técnico básico. '
              'Para instalaciones eléctricas certificadas, contacta un electricista.',
        );

      case 'electricidad':
      case 'electricista':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.electrical_services,
          accentColor: Colors.amber,
          warning: 'Verifica certificaciones para trabajos eléctricos mayores',
          legalDisclaimer: 'Asegúrate de que el trabajador tenga las certificaciones '
              'necesarias para trabajos eléctricos complejos.',
        );

      case 'plomeria':
      case 'plumber':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.plumbing,
          accentColor: Colors.blue,
          warning: 'Trabajos mayores pueden requerir permisos municipales',
        );

      case 'limpieza':
      case 'cleaning':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.cleaning_services,
          accentColor: Colors.green,
        );

      case 'construccion':
      case 'construction':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.construction,
          accentColor: Colors.orange,
          warning: 'Trabajos estructurales requieren permisos y certificaciones',
          legalDisclaimer: 'Trabajos de construcción mayores requieren permisos '
              'municipales y certificaciones profesionales.',
        );

      case 'jardineria':
      case 'gardening':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.local_florist,
          accentColor: Colors.green.shade700,
        );

      case 'montaje':
      case 'assembly':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.build,
          accentColor: Colors.brown,
        );

      case 'mudanza':
      case 'moving':
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.local_shipping,
          accentColor: Colors.indigo,
          warning: 'Verifica seguro de carga para objetos valiosos',
        );

      default:
        // Perfil por defecto
        return ServiceUXProfile(
          serviceId: serviceId,
          icon: Icons.handyman,
          accentColor: AppColors.primaryLight,
          legalDisclaimer: service?.legalDisclaimer,
        );
    }
  }

  /// Obtiene el perfil UX basado en el nombre del servicio
  ServiceUXProfile getProfileByName(String serviceName, ServiceModel? service) {
    final normalizedName = serviceName.toLowerCase().trim();
    
    // Mapeo de nombres comunes a IDs
    if (normalizedName.contains('electric') || normalizedName.contains('eléctric')) {
      return getProfile('electricidad', service);
    } else if (normalizedName.contains('plomer') || normalizedName.contains('fontaner')) {
      return getProfile('plomeria', service);
    } else if (normalizedName.contains('limpiez') || normalizedName.contains('clean')) {
      return getProfile('limpieza', service);
    } else if (normalizedName.contains('construc') || normalizedName.contains('build')) {
      return getProfile('construccion', service);
    } else if (normalizedName.contains('jardín') || normalizedName.contains('garden')) {
      return getProfile('jardineria', service);
    } else if (normalizedName.contains('montaje') || normalizedName.contains('assembly')) {
      return getProfile('montaje', service);
    } else if (normalizedName.contains('mudanza') || normalizedName.contains('moving')) {
      return getProfile('mudanza', service);
    } else if (normalizedName.contains('soporte') || normalizedName.contains('tech') || normalizedName.contains('it')) {
      return getProfile('support_it', service);
    }
    
    return getProfile(serviceName, service);
  }

  /// Obtiene el perfil UX basado en la categoría del servicio
  ServiceUXProfile getProfileByCategory(String category, ServiceModel? service) {
    return getProfile(category, service);
  }
}

