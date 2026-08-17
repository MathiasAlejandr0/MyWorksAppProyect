/// Modelo para disputas
/// 
/// Estados:
/// - open: Disputa abierta
/// - under_review: En revisión
/// - resolved: Resuelta
class DisputeModel {
  final String id;
  final String jobId;
  final String openedBy; // userId del que abre la disputa
  final String reason; // 'quality', 'payment', 'behavior', 'other'
  final String? description;
  final String status; // 'open', 'under_review', 'resolved'
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
      'jobId': jobId,
      'openedBy': openedBy,
      'reason': reason,
      'description': description,
      'status': status,
      'resolution': resolution,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DisputeModel.fromMap(Map<String, dynamic> map) {
    return DisputeModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      openedBy: map['openedBy'] as String,
      reason: map['reason'] as String,
      description: map['description'] as String?,
      status: map['status'] as String,
      resolution: map['resolution'] as String?,
      resolvedBy: map['resolvedBy'] as String?,
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.parse(map['resolvedAt'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
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

