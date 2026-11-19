import '../../domain/worker_custom_service.dart';
import '../../domain/worker_service_options_catalog.dart';
import '../../domain/worker_hours.dart';

class WorkerModel {
  final String userId;
  final String profession;
  final String? description;
  final double rating;
  final bool isAvailable;
  final double visitFee;
  final String serviceCategory;
  final Map<String, int> pricingTiers;
  final List<WorkerCustomService> customServices;
  final bool pricingConfigured;
  final String? workZone;
  final double? baseLatitude;
  final double? baseLongitude;
  final double serviceRadiusKm;
  /// `mapa` si el profesional la fijó; `comuna` si salió del texto de zona.
  final String? baseOrigin;
  /// Rechazos de invitaciones; penaliza el orden en búsquedas (no se muestra en UI).
  final int rejectionCount;
  /// Score de marketplace (0–100 + prioridad manual). Lo calcula el servidor.
  final double? listingScore;
  /// Override de admin: positivo = aparece antes, negativo = después.
  final int manualPriority;
  /// Trabajos en estado completado. Lo mantiene el servidor.
  final int completedJobs;
  /// Destacado del mes. Columna generada en Postgres.
  final bool isElite;
  /// Kilómetros con movilización en \$0.
  final double urbanRadiusKm;
  /// Cobro fijo de movilización fuera del radio urbano.
  final int outsideMobilizationFeeClp;
  /// Bloques semanales que el profesional publica para reservar.
  final List<WorkerHourSlot> availableHours;

  WorkerModel({
    required this.userId,
    required this.profession,
    this.description,
    this.rating = 0.0,
    this.isAvailable = true,
    this.visitFee = 15000,
    this.serviceCategory = 'general',
    Map<String, int>? pricingTiers,
    List<WorkerCustomService>? customServices,
    this.pricingConfigured = false,
    this.workZone,
    this.baseLatitude,
    this.baseLongitude,
    this.serviceRadiusKm = 7,
    this.baseOrigin,
    this.rejectionCount = 0,
    this.listingScore,
    this.manualPriority = 0,
    this.completedJobs = 0,
    this.isElite = false,
    this.urbanRadiusKm = 5,
    this.outsideMobilizationFeeClp = 0,
    List<WorkerHourSlot>? availableHours,
  })  : pricingTiers = pricingTiers ?? const {},
        customServices = customServices ?? const [],
        availableHours = availableHours ?? const [];

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': userId,
      'profesion': profession,
      'descripcion': description,
      'disponible': isAvailable ? 1 : 0,
      'tarifa_visita': visitFee,
      'precios_configurados': pricingConfigured ? 1 : 0,
      'zona_trabajo': workZone,
    };
  }

  /// Precios publicados: filas de `trabajador_precios` (codigo, monto_clp).
  static Map<String, int> _parsePricingTiers(dynamic raw) {
    if (raw is! List) return {};
    final tiers = <String, int>{};
    for (final row in raw) {
      if (row is! Map) continue;
      final code = row['codigo'];
      final amount = row['monto_clp'];
      if (code is String && amount is num) tiers[code] = amount.toInt();
    }
    return tiers;
  }

  /// Servicios propios: filas de `trabajador_servicios_extra`.
  static List<WorkerCustomService> _parseCustomServices(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final row in raw)
        if (row is Map &&
            row['id'] is String &&
            row['titulo'] is String &&
            row['monto_clp'] is num)
          WorkerCustomService(
            id: row['id'] as String,
            title: row['titulo'] as String,
            subtitle: row['subtitulo'] as String? ?? '',
            priceClp: (row['monto_clp'] as num).toInt(),
            unit: row['unidad'] == 'por_m2'
                ? WorkerPriceUnit.perSqm
                : WorkerPriceUnit.fixed,
          ),
    ];
  }

  /// Categoría del profesional: la menor de sus filas en `trabajador_servicios`
  /// (misma regla que `listar_profesionales_catalogo`). La RPC del catálogo
  /// ya la entrega como `categoria_servicio`.
  static String _parseCategory(Map<String, dynamic> map) {
    final linked = map['trabajador_servicios'];
    if (linked is List) {
      final codes = [
        for (final row in linked)
          if (row is Map && row['categoria_servicio'] is String)
            row['categoria_servicio'] as String,
      ]..sort();
      if (codes.isNotEmpty) return codes.first;
    }
    return map['categoria_servicio'] as String? ?? 'general';
  }

  /// `disponible` y `precios_configurados` llegan como entero, pero un
  /// booleano o un numeric no debe tirar abajo toda la ficha.
  static int _flag(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    final profession = map['profesion'];
    return WorkerModel(
      userId: map['id_usuario'] as String,
      profession: profession is String && profession.trim().isNotEmpty
          ? profession
          : 'Profesional',
      description: map['descripcion'] is String ? map['descripcion'] as String : null,
      rating: (map['calificacion'] as num?)?.toDouble() ??
          (map['rating'] as num?)?.toDouble() ??
          0.0,
      isAvailable: _flag(map['disponible']) == 1,
      visitFee: (map['tarifa_visita'] as num?)?.toDouble() ?? 15000,
      serviceCategory: _parseCategory(map),
      pricingTiers: _parsePricingTiers(map['trabajador_precios']),
      customServices: _parseCustomServices(map['trabajador_servicios_extra']),
      pricingConfigured: _flag(map['precios_configurados']) == 1,
      workZone:
          map['zona_trabajo'] is String ? map['zona_trabajo'] as String : null,
      baseLatitude: (map['latitud_base'] as num?)?.toDouble(),
      baseLongitude: (map['longitud_base'] as num?)?.toDouble(),
      serviceRadiusKm: (map['radio_servicio_km'] as num?)?.toDouble() ?? 7,
      baseOrigin:
          map['origen_base'] is String ? map['origen_base'] as String : null,
      rejectionCount: (map['conteo_rechazos'] as num?)?.toInt() ?? 0,
      listingScore: (map['score_listado'] as num?)?.toDouble(),
      manualPriority: (map['prioridad_manual'] as num?)?.toInt() ?? 0,
      completedJobs: (map['trabajos_completados'] as num?)?.toInt() ?? 0,
      isElite: map['es_elite'] == true,
      urbanRadiusKm: (map['radio_urbano_km'] as num?)?.toDouble() ?? 5,
      outsideMobilizationFeeClp:
          (map['tarifa_fuera_radio_clp'] as num?)?.toInt() ?? 0,
      availableHours: parseWorkerHours(map['horas_publicadas']),
    );
  }

  /// Fila de `listar_profesionales_catalogo`: ya viene filtrada (disponible,
  /// precio y verificado). Completa flags que la RPC no devuelve.
  /// La base viene redondeada (~1 km), salvo la ficha del propio profesional.
  factory WorkerModel.fromCatalogMap(Map<String, dynamic> map) {
    return WorkerModel.fromMap({
      ...map,
      'disponible': map['disponible'] ?? 1,
      'precios_configurados': map['precios_configurados'] ?? 1,
    });
  }

  WorkerModel copyWith({
    String? userId,
    String? profession,
    String? description,
    double? rating,
    bool? isAvailable,
    double? visitFee,
    String? serviceCategory,
    Map<String, int>? pricingTiers,
    List<WorkerCustomService>? customServices,
    bool? pricingConfigured,
    String? workZone,
    double? baseLatitude,
    double? baseLongitude,
    double? serviceRadiusKm,
    String? baseOrigin,
    int? rejectionCount,
    double? listingScore,
    int? manualPriority,
    int? completedJobs,
    bool? isElite,
    double? urbanRadiusKm,
    int? outsideMobilizationFeeClp,
    List<WorkerHourSlot>? availableHours,
  }) {
    return WorkerModel(
      userId: userId ?? this.userId,
      profession: profession ?? this.profession,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      visitFee: visitFee ?? this.visitFee,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      customServices: customServices ?? this.customServices,
      pricingConfigured: pricingConfigured ?? this.pricingConfigured,
      workZone: workZone ?? this.workZone,
      baseLatitude: baseLatitude ?? this.baseLatitude,
      baseLongitude: baseLongitude ?? this.baseLongitude,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      baseOrigin: baseOrigin ?? this.baseOrigin,
      rejectionCount: rejectionCount ?? this.rejectionCount,
      listingScore: listingScore ?? this.listingScore,
      manualPriority: manualPriority ?? this.manualPriority,
      completedJobs: completedJobs ?? this.completedJobs,
      isElite: isElite ?? this.isElite,
      urbanRadiusKm: urbanRadiusKm ?? this.urbanRadiusKm,
      outsideMobilizationFeeClp:
          outsideMobilizationFeeClp ?? this.outsideMobilizationFeeClp,
      availableHours: availableHours ?? this.availableHours,
    );
  }
}
