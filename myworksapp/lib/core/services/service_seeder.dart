import 'package:uuid/uuid.dart';
import '../database/repositories/service_repository.dart';
import '../database/repositories/service_config_repository.dart';
import '../database/models/service_model.dart';
import '../database/models/service_config_model.dart';
import '../utils/app_logger.dart';

/// Servicio para inicializar servicios en la base de datos
/// 
/// Agrega los nuevos servicios de alta demanda legalmente viables en Chile.
class ServiceSeeder {
  static final ServiceSeeder instance = ServiceSeeder._();
  ServiceSeeder._();

  final ServiceRepository _serviceRepository = ServiceRepository();
  final ServiceConfigRepository _configRepository = ServiceConfigRepository();

  /// Inicializa todos los servicios
  Future<void> seedServices() async {
    try {
      AppLogger.i('🌱 Inicializando servicios...');

      // Desactivar servicios duplicados antiguos
      await _deactivateDuplicateServices();

      // Servicios existentes (mantener compatibilidad)
      await _seedExistingServices();

      // Nuevos servicios de alta demanda
      await _seedCleaningServices();
      await _seedAssemblyServices();
      await _seedTechSupportServices();
      await _seedGardeningServices();
      await _seedMovingServices();

      AppLogger.i('✅ Servicios inicializados correctamente');
    } catch (e) {
      AppLogger.e('Error inicializando servicios', e);
    }
  }

  /// Desactiva servicios duplicados antiguos
  Future<void> _deactivateDuplicateServices() async {
    try {
      // Desactivar servicios individuales de limpieza (ahora consolidados)
      final cleaningServices = ['cleaning_general', 'cleaning_deep', 'cleaning_post_move'];
      for (final id in cleaningServices) {
        final service = await _serviceRepository.getServiceById(id);
        if (service != null && service.isActive) {
          final updated = service.copyWith(isActive: false, updatedAt: DateTime.now());
          await _serviceRepository.updateService(updated);
          AppLogger.d('Servicio desactivado: $id');
        }
      }

      // Desactivar servicios duplicados de electricidad (si existe "Electricista")
      final allServices = await _serviceRepository.getAllServices();
      final electricalServices = allServices.where((s) => 
        s.category == ServiceCategories.electrical && 
        s.name.toLowerCase().contains('electricista')
      ).toList();
      
      for (final service in electricalServices) {
        if (service.id != 'electrical') {
          final updated = service.copyWith(isActive: false, updatedAt: DateTime.now());
          await _serviceRepository.updateService(updated);
          AppLogger.d('Servicio duplicado desactivado: ${service.id}');
        }
      }
    } catch (e) {
      AppLogger.e('Error desactivando servicios duplicados', e);
    }
  }

  /// Servicios existentes (mantener compatibilidad)
  Future<void> _seedExistingServices() async {
    final now = DateTime.now();
    
    // Construcción
    await _createServiceIfNotExists(
      id: 'construction',
      name: 'Construcción',
      description: 'Servicios de construcción y reparación',
      category: ServiceCategories.construction,
      pricingModel: PricingModels.hourly,
    );

    // Plomería
    await _createServiceIfNotExists(
      id: 'plumbing',
      name: 'Plomería',
      description: 'Reparación e instalación de sistemas de plomería',
      category: ServiceCategories.plumbing,
      pricingModel: PricingModels.hourly,
    );

    // Electricidad
    await _createServiceIfNotExists(
      id: 'electrical',
      name: 'Electricidad',
      description: 'Reparación e instalación eléctrica básica',
      category: ServiceCategories.electrical,
      pricingModel: PricingModels.hourly,
    );
  }

  /// Servicios de limpieza - Consolidado en un solo servicio con variantes
  Future<void> _seedCleaningServices() async {
    // Crear un solo servicio principal de Limpieza
    await _createServiceIfNotExists(
      id: 'cleaning',
      name: 'Limpieza',
      description: 'Servicios de limpieza para tu hogar u oficina',
      category: ServiceCategories.cleaning,
      pricingModel: PricingModels.hourly,
      legalDisclaimer: 'No incluye productos químicos industriales ni sanitización clínica.',
    );

    // Configuración con variantes y campos específicos
    await _createServiceConfig(
      serviceId: 'cleaning',
      schema: {
        'variants': [
          {
            'id': 'general',
            'name': 'Limpieza General',
            'description': 'Limpieza general de hogar u oficina',
            'pricingModel': 'hourly',
            'basePrice': 15000,
            'priceRange': {'min': 12000, 'max': 20000},
          },
          {
            'id': 'deep',
            'name': 'Limpieza Profunda',
            'description': 'Limpieza profunda y detallada',
            'pricingModel': 'hourly',
            'basePrice': 20000,
            'priceRange': {'min': 18000, 'max': 25000},
          },
          {
            'id': 'post_move',
            'name': 'Limpieza Post Mudanza',
            'description': 'Limpieza después de mudanza',
            'pricingModel': 'fixed',
            'basePrice': 50000,
            'priceRange': {'min': 40000, 'max': 70000},
          },
        ],
        'fields': [
          {'name': 'cleaningType', 'type': 'select', 'label': 'Tipo de limpieza', 'required': true, 'options': ['General', 'Profunda', 'Post Mudanza']},
          {'name': 'size', 'type': 'select', 'label': 'Tamaño', 'required': true, 'options': ['Departamento', 'Casa pequeña', 'Casa mediana', 'Casa grande']},
          {'name': 'frequency', 'type': 'select', 'label': 'Frecuencia', 'required': true, 'options': ['Única vez', 'Semanal', 'Quincenal', 'Mensual']},
          {'name': 'rooms', 'type': 'number', 'label': 'Número de habitaciones', 'required': false},
          {'name': 'hasPets', 'type': 'boolean', 'label': '¿Hay mascotas?', 'required': false},
        ],
      },
    );
  }

  /// Servicios de armado
  Future<void> _seedAssemblyServices() async {
    await _createServiceIfNotExists(
      id: 'assembly_furniture',
      name: 'Armado de Muebles',
      description: 'Armado de muebles tipo IKEA, camas, escritorios, repisas',
      category: ServiceCategories.assembly,
      pricingModel: PricingModels.perItem,
    );

    // Configuración para armado
    await _createServiceConfig(
      serviceId: 'assembly_furniture',
      schema: {
        'fields': [
          {'name': 'furnitureType', 'type': 'text', 'label': 'Tipo de mueble', 'required': true},
          {'name': 'quantity', 'type': 'number', 'label': 'Cantidad', 'required': true},
          {'name': 'brand', 'type': 'text', 'label': 'Marca (opcional)', 'required': false},
          {'name': 'toolsIncluded', 'type': 'boolean', 'label': '¿Incluye herramientas?', 'required': false},
        ],
      },
    );
  }

  /// Servicios de soporte técnico
  Future<void> _seedTechSupportServices() async {
    await _createServiceIfNotExists(
      id: 'tech_support_basic',
      name: 'Soporte Técnico Básico',
      description: 'Configuración WiFi, instalación impresoras, soporte PC/notebook, ayuda smartphones',
      category: ServiceCategories.techSupport,
      pricingModel: PricingModels.hourly,
      legalDisclaimer: 'NO incluye instalaciones eléctricas, cableado estructurado ni cámaras de seguridad certificadas.',
    );

    // Configuración para soporte técnico
    await _createServiceConfig(
      serviceId: 'tech_support_basic',
      schema: {
        'fields': [
          {'name': 'deviceType', 'type': 'select', 'label': 'Tipo de dispositivo', 'required': true, 'options': ['PC/Notebook', 'Smartphone', 'Tablet', 'Impresora', 'Router/WiFi', 'Otro']},
          {'name': 'problem', 'type': 'text', 'label': 'Problema principal', 'required': true},
          {'name': 'urgency', 'type': 'select', 'label': 'Urgencia', 'required': true, 'options': ['Normal', 'Hoy mismo']},
        ],
      },
    );
  }

  /// Servicios de jardinería
  Future<void> _seedGardeningServices() async {
    await _createServiceIfNotExists(
      id: 'gardening_basic',
      name: 'Jardinería Básica',
      description: 'Corte de pasto, limpieza de jardín, mantención básica',
      category: ServiceCategories.gardening,
      pricingModel: PricingModels.hourly,
      legalDisclaimer: 'NO incluye tala de árboles grandes ni uso de maquinaria pesada.',
    );

    // Configuración para jardinería
    await _createServiceConfig(
      serviceId: 'gardening_basic',
      schema: {
        'fields': [
          {'name': 'size', 'type': 'select', 'label': 'Tamaño aproximado', 'required': true, 'options': ['Pequeño (<50m²)', 'Mediano (50-200m²)', 'Grande (>200m²)']},
          {'name': 'hasOwnTools', 'type': 'boolean', 'label': '¿Tienes herramientas propias?', 'required': false},
        ],
      },
    );
  }

  /// Servicios de mudanzas
  Future<void> _seedMovingServices() async {
    await _createServiceIfNotExists(
      id: 'moving_small',
      name: 'Mudanzas Pequeñas',
      description: 'Carga/descarga y traslado dentro de la ciudad',
      category: ServiceCategories.moving,
      pricingModel: PricingModels.fixed,
      legalDisclaimer: 'Solo mudanzas pequeñas dentro de la ciudad. NO transporte comercial ni internacional. El trabajador debe contar con su propio vehículo.',
    );

    // Configuración para mudanzas
    await _createServiceConfig(
      serviceId: 'moving_small',
      schema: {
        'fields': [
          {'name': 'origin', 'type': 'text', 'label': 'Dirección de origen', 'required': true},
          {'name': 'destination', 'type': 'text', 'label': 'Dirección de destino', 'required': true},
          {'name': 'originFloor', 'type': 'select', 'label': 'Piso origen', 'required': true, 'options': ['Planta baja', '1-3 pisos (con ascensor)', '1-3 pisos (sin ascensor)', '4+ pisos']},
          {'name': 'destinationFloor', 'type': 'select', 'label': 'Piso destino', 'required': true, 'options': ['Planta baja', '1-3 pisos (con ascensor)', '1-3 pisos (sin ascensor)', '4+ pisos']},
          {'name': 'volume', 'type': 'select', 'label': 'Volumen estimado', 'required': true, 'options': ['Pequeño (1-2 habitaciones)', 'Mediano (3-4 habitaciones)', 'Grande (5+ habitaciones)']},
          {'name': 'helpers', 'type': 'select', 'label': 'Ayuda requerida', 'required': true, 'options': ['1 persona', '2 personas']},
        ],
      },
    );
  }

  /// Crea un servicio si no existe
  Future<void> _createServiceIfNotExists({
    required String id,
    required String name,
    required String description,
    required String category,
    required String pricingModel,
    String? legalDisclaimer,
  }) async {
    try {
      final existing = await _serviceRepository.getServiceById(id);
      if (existing != null) {
        AppLogger.d('Servicio ya existe: $id');
        return;
      }

      final now = DateTime.now();
      final service = ServiceModel(
        id: id,
        name: name,
        description: description,
        category: category,
        isActive: true,
        requiresCertification: false,
        pricingModel: pricingModel,
        legalDisclaimer: legalDisclaimer,
        createdAt: now,
        updatedAt: now,
      );

      await _serviceRepository.createService(service);
      AppLogger.d('Servicio creado: $name');
    } catch (e) {
      AppLogger.e('Error creando servicio $id', e);
    }
  }

  /// Crea configuración de servicio
  Future<void> _createServiceConfig({
    required String serviceId,
    required Map<String, dynamic> schema,
  }) async {
    try {
      final existing = await _configRepository.getConfigByServiceId(serviceId);
      if (existing != null) {
        AppLogger.d('Configuración ya existe para servicio: $serviceId');
        return;
      }

      final now = DateTime.now();
      final config = ServiceConfigModel(
        id: const Uuid().v4(),
        serviceId: serviceId,
        configSchema: schema,
        createdAt: now,
        updatedAt: now,
      );

      await _configRepository.createConfig(config);
      AppLogger.d('Configuración creada para servicio: $serviceId');
    } catch (e) {
      AppLogger.e('Error creando configuración para servicio $serviceId', e);
    }
  }
}

