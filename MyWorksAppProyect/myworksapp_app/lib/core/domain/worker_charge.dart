/// Un cobro del profesional tal como lo entrega la vista `cobros_profesional`.
///
/// La base calcula bruto, comisión y neto (función `comision_servicio_clp`):
/// la app solo los muestra, no los recalcula.
class WorkerCharge {
  const WorkerCharge({
    required this.paymentId,
    required this.jobId,
    required this.paymentType,
    required this.paymentStatus,
    required this.grossClp,
    required this.feeClp,
    required this.netClp,
    this.transferStatus,
    this.transferReference,
    this.settledAt,
    this.releasedAt,
    this.createdAt,
  });

  static const String view = 'cobros_profesional';
  static const String columns =
      'id_pago, id_trabajo, id_trabajador, tipo_pago, estado_pago, bruto_clp, '
      'comision_clp, neto_clp, estado_transferencia, referencia_transferencia, '
      'liquidado_en, liberado_en, creado_en';

  final String paymentId;
  final String jobId;
  final String paymentType;
  final String paymentStatus;

  /// Lo que pagó el cliente.
  final int grossClp;

  /// Comisión del servicio que se descuenta al profesional.
  final int feeClp;

  /// Lo que se le transfiere al profesional.
  final int netClp;

  /// `transferido` cuando el administrador ya registró la transferencia.
  final String? transferStatus;
  final String? transferReference;
  final DateTime? settledAt;
  final DateTime? releasedAt;
  final DateTime? createdAt;

  factory WorkerCharge.fromRow(Map<String, dynamic> row) {
    final gross = _int(row['bruto_clp']);
    final fee = _int(row['comision_clp']);
    final net = row['neto_clp'] == null ? gross - fee : _int(row['neto_clp']);
    return WorkerCharge(
      paymentId: '${row['id_pago'] ?? ''}',
      jobId: '${row['id_trabajo'] ?? ''}',
      paymentType: '${row['tipo_pago'] ?? 'principal'}',
      paymentStatus: '${row['estado_pago'] ?? ''}',
      grossClp: gross,
      feeClp: fee,
      netClp: net,
      transferStatus: row['estado_transferencia'] as String?,
      transferReference: row['referencia_transferencia'] as String?,
      settledAt: _date(row['liquidado_en']),
      releasedAt: _date(row['liberado_en']),
      createdAt: _date(row['creado_en']),
    );
  }

  static int _int(Object? value) {
    if (value is num) return value.round();
    if (value is String) return num.tryParse(value)?.round() ?? 0;
    return 0;
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));
    return parsed;
  }
}
