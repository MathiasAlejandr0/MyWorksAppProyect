/// Modelo para disputas
///
/// Estados:
/// - abierta: Disputa abierta
/// - en_revision: En revisión
/// - resuelta: Resuelta
class DisputeModel {
  final String id;
  final String jobId;
  final String openedBy; // userId del que abre la disputa
  final String reason; // 'quality', 'payment', 'behavior', 'other'
  final String? description;
  final String status; // 'abierta', 'en_revision', 'resuelta'
  final String? resolution; // Resolución de la disputa
  final String? resolvedBy; // Admin que resolvió
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisputeModel({
    required this.id,
    required this.jobId,
    required this.openedBy,
    required this.reason,
    this.description,
    required this.status,
    this.resolution,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_trabajo': jobId,
      'abierta_por': openedBy,
      'motivo': reason,
      'descripcion': description,
      'estado': status,
      'resolucion': resolution,
      'resuelta_por': resolvedBy,
      'resuelta_en': resolvedAt?.toIso8601String(),
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory DisputeModel.fromMap(Map<String, dynamic> map) {
    return DisputeModel(
      id: map['id'] as String,
      jobId: map['id_trabajo'] as String,
      openedBy: map['abierta_por'] as String,
      reason: map['motivo'] as String,
      description: map['descripcion'] as String?,
      status: map['estado'] as String,
      resolution: map['resolucion'] as String?,
      resolvedBy: map['resuelta_por'] as String?,
      resolvedAt: map['resuelta_en'] != null
          ? DateTime.parse(map['resuelta_en'] as String)
          : null,
      createdAt: DateTime.parse(map['creado_en'] as String),
      updatedAt: DateTime.parse(map['actualizado_en'] as String),
    );
  }

  DisputeModel copyWith({
    String? id,
    String? jobId,
    String? openedBy,
    String? reason,
    String? description,
    String? status,
    String? resolution,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DisputeModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      openedBy: openedBy ?? this.openedBy,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
