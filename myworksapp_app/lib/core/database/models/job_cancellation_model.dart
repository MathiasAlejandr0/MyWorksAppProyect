class JobCancellationModel {
  final String id;
  final String jobId;
  final String cancelledBy; // userId de quien cancela
  final String reason; // Motivo obligatorio
  final DateTime cancelledAt;

  JobCancellationModel({
    required this.id,
    required this.jobId,
    required this.cancelledBy,
    required this.reason,
    required this.cancelledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_trabajo': jobId,
      'cancelado_por': cancelledBy,
      'motivo': reason,
      'cancelado_en': cancelledAt.toIso8601String(),
    };
  }

  factory JobCancellationModel.fromMap(Map<String, dynamic> map) {
    return JobCancellationModel(
      id: map['id'] as String,
      jobId: map['id_trabajo'] as String,
      cancelledBy: map['cancelado_por'] as String,
      reason: map['motivo'] as String,
      cancelledAt: DateTime.parse(map['cancelado_en'] as String),
    );
  }
}

