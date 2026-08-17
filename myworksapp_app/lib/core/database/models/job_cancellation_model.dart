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
      'jobId': jobId,
      'cancelledBy': cancelledBy,
      'reason': reason,
      'cancelledAt': cancelledAt.toIso8601String(),
    };
  }

  factory JobCancellationModel.fromMap(Map<String, dynamic> map) {
    return JobCancellationModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      cancelledBy: map['cancelledBy'] as String,
      reason: map['reason'] as String,
      cancelledAt: DateTime.parse(map['cancelledAt'] as String),
    );
  }
}

