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
  /// Rechazos de invitaciones; penaliza el orden en búsquedas (no se muestra en UI).
  final int rejectionCount;

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
    this.rejectionCount = 0,
  })  : pricingTiers = pricingTiers ?? const {},
        customServices = customServices ?? const [];

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': userId,
      'profesion': profession,
      'descripcion': description,
      'calificacion': rating,
      'disponible': isAvailable ? 1 : 0,
      'tarifa_visita': visitFee,
      'categoria_servicio': serviceCategory,
      'niveles_precio': pricingTiers,
      'servicios_personalizados': customServices.map((s) => s.toMap()).toList(),
      'precios_configurados': pricingConfigured ? 1 : 0,
      'zona_trabajo': workZone,
      'conteo_rechazos': rejectionCount,
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
      rejectionCount: (map['conteo_rechazos'] as num?)?.toInt() ?? 0,
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
    int? rejectionCount,
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
      rejectionCount: rejectionCount ?? this.rejectionCount,
    );
  }
}
