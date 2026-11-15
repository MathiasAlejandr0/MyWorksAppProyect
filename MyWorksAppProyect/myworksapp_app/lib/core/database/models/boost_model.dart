/// Modelo para boosts
class BoostModel {
  final String id;
  final String workerId;
  final String boostType; // 'visibility', 'priority', 'featured'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  BoostModel({
    required this.id,
    required this.workerId,
    required this.boostType,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_trabajador': workerId,
      'tipo_impulso': boostType,
      'fecha_inicio': startDate.toIso8601String(),
      'fecha_fin': endDate.toIso8601String(),
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory BoostModel.fromMap(Map<String, dynamic> map) {
    return BoostModel(
      id: map['id'] as String,
      workerId: map['id_trabajador'] as String,
      boostType: map['tipo_impulso'] as String,
      startDate: DateTime.parse(map['fecha_inicio'] as String),
      endDate: DateTime.parse(map['fecha_fin'] as String),
      createdAt: DateTime.parse(map['creado_en'] as String),
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

