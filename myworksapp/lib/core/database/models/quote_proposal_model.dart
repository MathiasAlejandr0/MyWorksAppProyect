import 'dart:convert';

class QuoteProposalModel {
  final String id;
  final String jobId;
  final String workerId;
  final int montoTotalClp;
  final String descripcion;
  final DateTime? validezHasta;
  final Map<String, dynamic>? desglose;
  final String estado;
  final DateTime createdAt;

  QuoteProposalModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.montoTotalClp,
    required this.descripcion,
    this.validezHasta,
    this.desglose,
    required this.estado,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobId': jobId,
        'workerId': workerId,
        'montoTotalClp': montoTotalClp,
        'descripcion': descripcion,
        'validezHasta': validezHasta?.toIso8601String(),
        'desglose': desglose != null ? jsonEncode(desglose) : null,
        'estado': estado,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuoteProposalModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? desglose;
    if (map['desglose'] != null) {
      try {
        desglose = jsonDecode(map['desglose'] as String) as Map<String, dynamic>;
      } catch (_) {
        desglose = null;
      }
    }
    return QuoteProposalModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      workerId: map['workerId'] as String,
      montoTotalClp: (map['montoTotalClp'] as num).toInt(),
      descripcion: map['descripcion'] as String,
      validezHasta: map['validezHasta'] != null
          ? DateTime.parse(map['validezHasta'] as String)
          : null,
      desglose: desglose,
      estado: map['estado'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
