/// Modelo para eventos de abuso
class AbuseEventModel {
  final String id;
  final String userId;
  final String abuseType; // 'excessive_jobs', 'excessive_rejections', 'excessive_cancellations'
  final int count;
  final DateTime detectedAt;
  final String? actionTaken; // 'shadow_ban', 'trust_penalty', 'temporary_ban'
  final DateTime? actionTakenAt;
  final bool isResolved;

  AbuseEventModel({
    required this.id,
    required this.userId,
    required this.abuseType,
    required this.count,
    required this.detectedAt,
    this.actionTaken,
    this.actionTakenAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_usuario': userId,
      'tipo_abuso': abuseType,
      'conteo': count,
      'detectado_en': detectedAt.toIso8601String(),
      'accion_tomada': actionTaken,
      'accion_tomada_en': actionTakenAt?.toIso8601String(),
      'resuelto': isResolved ? 1 : 0,
    };
  }

  factory AbuseEventModel.fromMap(Map<String, dynamic> map) {
    return AbuseEventModel(
      id: map['id'] as String,
      userId: map['id_usuario'] as String,
      abuseType: map['tipo_abuso'] as String,
      count: map['conteo'] as int,
      detectedAt: DateTime.parse(map['detectado_en'] as String),
      actionTaken: map['accion_tomada'] as String?,
      actionTakenAt: map['accion_tomada_en'] != null
          ? DateTime.parse(map['accion_tomada_en'] as String)
          : null,
      isResolved: (map['resuelto'] as int? ?? 0) == 1,
    );
  }

  AbuseEventModel copyWith({
    String? id,
    String? userId,
    String? abuseType,
    int? count,
    DateTime? detectedAt,
    String? actionTaken,
    DateTime? actionTakenAt,
    bool? isResolved,
  }) {
    return AbuseEventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      abuseType: abuseType ?? this.abuseType,
      count: count ?? this.count,
      detectedAt: detectedAt ?? this.detectedAt,
      actionTaken: actionTaken ?? this.actionTaken,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

