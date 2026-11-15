import '../database/models/service_model.dart';

/// Relaciona servicios con categorías de trabajadores demo.
class ServiceWorkerMapper {
  ServiceWorkerMapper._();

  static const Map<String, String> categoryLabels = {
    ServiceCategories.construction: 'Construcción',
    ServiceCategories.plumbing: 'Plomería',
    ServiceCategories.electrical: 'Electricidad',
    ServiceCategories.cleaning: 'Limpieza',
    ServiceCategories.assembly: 'Armado de muebles',
    ServiceCategories.techSupport: 'Soporte técnico',
    ServiceCategories.gardening: 'Jardinería',
    ServiceCategories.moving: 'Mudanzas',
  };

  /// Profesiones disponibles al registrarse (una por categoría de servicio).
  static List<String> get registrationProfessions => [
        professionForCategory(ServiceCategories.construction),
        professionForCategory(ServiceCategories.plumbing),
        professionForCategory(ServiceCategories.electrical),
        professionForCategory(ServiceCategories.cleaning),
        professionForCategory(ServiceCategories.assembly),
        professionForCategory(ServiceCategories.techSupport),
        professionForCategory(ServiceCategories.gardening),
        professionForCategory(ServiceCategories.moving),
      ];

  static String? labelForCategory(String? category) => categoryLabels[category];

  static String categoryForProfession(String profession) {
    for (final entry in categoryLabels.entries) {
      if (professionForCategory(entry.key) == profession) {
        return entry.key;
      }
    }
    return 'general';
  }

  static String professionForCategory(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return 'Maestro Constructor';
      case ServiceCategories.plumbing:
        return 'Gasfiter';
      case ServiceCategories.electrical:
        return 'Electricista';
      case ServiceCategories.cleaning:
        return 'Especialista en Limpieza';
      case ServiceCategories.assembly:
        return 'Armador de Muebles';
      case ServiceCategories.techSupport:
        return 'Soporte Técnico';
      case ServiceCategories.gardening:
        return 'Jardinero';
      case ServiceCategories.moving:
        return 'Especialista en Mudanzas';
      default:
        return 'Técnico General';
    }
  }
}
