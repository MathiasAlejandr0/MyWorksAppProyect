class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String? description;
  final String status; // 'pendiente', 'revisado', 'resuelto', 'descartado'
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    this.status = 'pendiente',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_reportante': reporterId,
      'id_usuario_reportado': reportedUserId,
      'motivo': reason,
      'descripcion': description,
      'estado': status,
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] as String,
      reporterId: map['id_reportante'] as String,
      reportedUserId: map['id_usuario_reportado'] as String,
      reason: map['motivo'] as String,
      description: map['descripcion'] as String?,
      status: map['estado'] as String? ?? 'pendiente',
      createdAt: DateTime.parse(map['creado_en'] as String),
    );
  }
}
