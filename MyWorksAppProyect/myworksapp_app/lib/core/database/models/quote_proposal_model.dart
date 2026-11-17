class QuoteProposalModel {
  final String id;
  final String jobId;
  final String workerId;
  final int montoTotalClp;
  final String descripcion;
  final DateTime? validezHasta;
  /// Vista del desglose: `materiales_clp`, `mano_obra_clp` (líneas de
  /// `propuesta_cotizacion_items`) y `horas_estimadas` (columna de la cotización).
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
        'horas_estimadas': desglose?['horas_estimadas'],
        'estado': estado,
        'creado_en': createdAt.toIso8601String(),
      };

  /// Líneas de dinero del desglose para `propuesta_cotizacion_items`.
  /// `linea` numera desde 1 en el orden materiales, mano de obra.
  List<Map<String, dynamic>> itemRows() {
    final lines = <(String, num)>[
      if (desglose?['materiales_clp'] is num)
        ('materiales', desglose!['materiales_clp'] as num),
      if (desglose?['mano_obra_clp'] is num)
        ('mano_obra', desglose!['mano_obra_clp'] as num),
    ];
    return [
      for (var i = 0; i < lines.length; i++)
        {
          'id_propuesta': id,
          'linea': i + 1,
          'concepto': lines[i].$1,
          'monto': lines[i].$2,
        },
    ];
  }

  static Map<String, dynamic>? _desgloseFrom(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    final items = map['propuesta_cotizacion_items'];
    if (items is List) {
      for (final item in items) {
        if (item is! Map || item['monto'] is! num) continue;
        if (item['concepto'] == 'materiales') {
          result['materiales_clp'] = item['monto'];
        } else if (item['concepto'] == 'mano_obra') {
          result['mano_obra_clp'] = item['monto'];
        }
      }
    }
    final hours = map['horas_estimadas'];
    if (hours is num) result['horas_estimadas'] = hours;
    return result.isEmpty ? null : result;
  }

  factory QuoteProposalModel.fromMap(Map<String, dynamic> map) {
    final desglose = _desgloseFrom(map);
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
