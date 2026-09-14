/// Modelo para suscripciones
class SubscriptionModel {
  final String id;
  final String userId;
  final String planType; // 'free', 'basic', 'premium', 'enterprise'
  final String status; // 'active', 'cancelled', 'expired'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planType,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_usuario': userId,
      'tipo_plan': planType,
      'estado': status,
      'fecha_inicio': startDate.toIso8601String(),
      'fecha_fin': endDate?.toIso8601String(),
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] as String,
      userId: map['id_usuario'] as String,
      planType: map['tipo_plan'] as String,
      status: map['estado'] as String,
      startDate: DateTime.parse(map['fecha_inicio'] as String),
      endDate: map['fecha_fin'] != null
          ? DateTime.parse(map['fecha_fin'] as String)
          : null,
      createdAt: DateTime.parse(map['creado_en'] as String),
      updatedAt: DateTime.parse(map['actualizado_en'] as String),
    );
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? planType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

