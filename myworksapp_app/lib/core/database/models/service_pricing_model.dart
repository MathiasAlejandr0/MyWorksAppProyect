/// Modelo para precios de servicios
class ServicePricingModel {
  final String id;
  final String serviceId;
  final double basePrice; // Precio base del servicio
  final double minimumFee; // Tarifa mínima
  final double hourlyRate; // Precio por hora
  final String? currency; // Moneda (ej: 'USD', 'MXN', 'ARS')
  final DateTime createdAt;
  final DateTime updatedAt;

  ServicePricingModel({
    required this.id,
    required this.serviceId,
    required this.basePrice,
    required this.minimumFee,
    required this.hourlyRate,
    this.currency = 'USD',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_servicio': serviceId,
      'basePrice': basePrice,
      'minimumFee': minimumFee,
      'hourlyRate': hourlyRate,
      'moneda': currency ?? 'USD',
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory ServicePricingModel.fromMap(Map<String, dynamic> map) {
    return ServicePricingModel(
      id: map['id'] as String,
      serviceId: map['id_servicio'] as String,
      basePrice: (map['basePrice'] as num).toDouble(),
      minimumFee: (map['minimumFee'] as num).toDouble(),
      hourlyRate: (map['hourlyRate'] as num).toDouble(),
      currency: map['moneda'] as String? ?? 'USD',
      createdAt: DateTime.parse(map['creado_en'] as String),
      updatedAt: DateTime.parse(map['actualizado_en'] as String),
    );
  }

  ServicePricingModel copyWith({
    String? id,
    String? serviceId,
    double? basePrice,
    double? minimumFee,
    double? hourlyRate,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServicePricingModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      basePrice: basePrice ?? this.basePrice,
      minimumFee: minimumFee ?? this.minimumFee,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

