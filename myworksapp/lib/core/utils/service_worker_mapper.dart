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
