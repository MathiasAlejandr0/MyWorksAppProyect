/// Desglose entero que devuelve `resumen_cobro_trabajo`.
/// Tarifa + traslado = total, y comisión + neto = total.
class JobChargePreview {
  const JobChargePreview({
    required this.totalClp,
    required this.serviceClp,
    required this.transportClp,
    required this.feeClp,
    required this.payoutClp,
  });

  final int totalClp;
  final int serviceClp;
  final int transportClp;
  final int feeClp;
  final int payoutClp;

  factory JobChargePreview.fromMap(Map<String, dynamic> map) {
    int clp(String key) {
      final value = map[key];
      if (value is num) return value.round();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    return JobChargePreview(
      totalClp: clp('total_clp'),
      serviceClp: clp('tarifa_clp'),
      transportClp: clp('traslado_clp'),
      feeClp: clp('comision_clp'),
      payoutClp: clp('neto_clp'),
    );
  }
}
