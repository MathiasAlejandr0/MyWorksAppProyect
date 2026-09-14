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
        'id_trabajo': jobId,
        'id_trabajador': workerId,
        'monto_total_clp': montoTotalClp,
        'descripcion': descripcion,
        'validez_hasta': validezHasta?.toIso8601String(),
        'desglose': desglose != null ? jsonEncode(desglose) : null,
        'estado': estado,
        'creado_en': createdAt.toIso8601String(),
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
      jobId: map['id_trabajo'] as String,
      workerId: map['id_trabajador'] as String,
      montoTotalClp: (map['monto_total_clp'] as num).toInt(),
      descripcion: map['descripcion'] as String,
      validezHasta: map['validez_hasta'] != null
          ? DateTime.parse(map['validez_hasta'] as String)
          : null,
      desglose: desglose,
      estado: map['estado'] as String,
      createdAt: DateTime.parse(map['creado_en'] as String),
    );
  }
}
