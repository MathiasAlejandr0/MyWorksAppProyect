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
    this.rejectionCount = 0,
  })  : pricingTiers = pricingTiers ?? const {},
        customServices = customServices ?? const [];

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'profession': profession,
      'description': description,
      'rating': rating,
      'isAvailable': isAvailable ? 1 : 0,
      'visitFee': visitFee,
      'serviceCategory': serviceCategory,
      'pricingTiers': pricingTiers,
      'customServices': customServices.map((s) => s.toMap()).toList(),
      'pricingConfigured': pricingConfigured ? 1 : 0,
      'rejectionCount': rejectionCount,
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
      userId: map['userId'] as String,
      profession: map['profession'] as String,
      description: map['description'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      isAvailable: (map['isAvailable'] as int? ?? 0) == 1,
      visitFee: (map['visitFee'] as num?)?.toDouble() ?? 15000,
      serviceCategory: map['serviceCategory'] as String? ?? 'general',
      pricingTiers: _parsePricingTiers(map['pricingTiers']),
      customServices: WorkerCustomService.listFromJson(map['customServices']),
      pricingConfigured: (map['pricingConfigured'] as int? ?? 0) == 1,
      rejectionCount: (map['rejectionCount'] as num?)?.toInt() ?? 0,
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
      rejectionCount: rejectionCount ?? this.rejectionCount,
    );
  }
}
