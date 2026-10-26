import '../../domain/worker_custom_service.dart';

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
  })  : pricingTiers = pricingTiers ?? const {},
        customServices = customServices ?? const [];

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': userId,
      'profesion': profession,
      'descripcion': description,
      'disponible': isAvailable ? 1 : 0,
      'tarifa_visita': visitFee,
      'categoria_servicio': serviceCategory,
      'niveles_precio': pricingTiers,
      'servicios_personalizados': customServices.map((s) => s.toMap()).toList(),
      'precios_configurados': pricingConfigured ? 1 : 0,
      'zona_trabajo': workZone,
    };
  }

  static Map<String, int> _parsePricingTiers(dynamic raw) {
    if (raw == null) return {};
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as num).toInt(),
      ),
    );
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkerModel(
      userId: map['id_usuario'] as String,
      profession: map['profesion'] as String,
      description: map['descripcion'] as String?,
      rating: (map['calificacion'] as num?)?.toDouble() ??
          (map['rating'] as num?)?.toDouble() ??
          0.0,
      isAvailable: (map['disponible'] as int? ?? 0) == 1,
      visitFee: (map['tarifa_visita'] as num?)?.toDouble() ?? 15000,
      serviceCategory: map['categoria_servicio'] as String? ?? 'general',
      pricingTiers: _parsePricingTiers(map['niveles_precio']),
      customServices: WorkerCustomService.listFromJson(map['servicios_personalizados']),
      pricingConfigured: (map['precios_configurados'] as int? ?? 0) == 1,
      workZone: map['zona_trabajo'] as String?,
      baseLatitude: (map['latitud_base'] as num?)?.toDouble(),
      baseLongitude: (map['longitud_base'] as num?)?.toDouble(),
      serviceRadiusKm: (map['radio_servicio_km'] as num?)?.toDouble() ?? 7,
      baseOrigin: map['origen_base'] as String?,
      rejectionCount: (map['conteo_rechazos'] as num?)?.toInt() ?? 0,
      listingScore: (map['score_listado'] as num?)?.toDouble(),
      manualPriority: (map['prioridad_manual'] as num?)?.toInt() ?? 0,
      completedJobs: (map['trabajos_completados'] as num?)?.toInt() ?? 0,
      isElite: map['es_elite'] == true,
      urbanRadiusKm: (map['radio_urbano_km'] as num?)?.toDouble() ?? 5,
      outsideMobilizationFeeClp:
          (map['tarifa_fuera_radio_clp'] as num?)?.toInt() ?? 0,
    );
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
    );
  }
}
