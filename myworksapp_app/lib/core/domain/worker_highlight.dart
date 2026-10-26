import 'distance_match.dart';
import '../database/models/worker_model.dart';

/// Destacado del mes: misma regla que `trabajadores.es_elite` en Postgres.
const double eliteMinRating = 4.7;
const int eliteMinCompletedJobs = 5;

/// Bajo este piso el catálogo no lo muestra. Entre 3.0 y 3.5 sigue, más abajo.
const double lowRatingFloor = 3.0;
const double lowRatingDemote = 3.5;

bool isEliteWorker(WorkerModel worker) {
  if (worker.isElite) return true;
  return worker.rating >= eliteMinRating &&
      worker.completedJobs >= eliteMinCompletedJobs;
}

/// Nota visible para el cliente. Null si todavía no hay punto del cliente.
class CoverageNotice {
  const CoverageNotice({required this.inside, required this.text});

  /// True dentro, false fuera, null si falta la ubicación del cliente o la base.
  final bool? inside;
  final String text;
}

String _clp(int amount) {
  final raw = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
    buffer.write(raw[i]);
  }
  return '\$$buffer';
}

CoverageNotice coverageNotice({
  required WorkerModel worker,
  double? clientLatitude,
  double? clientLongitude,
}) {
  final urban = worker.urbanRadiusKm;
  final fee = worker.outsideMobilizationFeeClp;
  final feeLabel = fee <= 0 ? 'sin recargo' : _clp(fee);
  final baseLat = worker.baseLatitude;
  final baseLng = worker.baseLongitude;
  if (clientLatitude == null ||
      clientLongitude == null ||
      baseLat == null ||
      baseLng == null) {
    return CoverageNotice(
      inside: null,
      text:
          'Radio urbano ${urban.toStringAsFixed(0)} km: movilización \$0 dentro. Fuera, $feeLabel.',
    );
  }

  final km = haversineKm(baseLat, baseLng, clientLatitude, clientLongitude);
  if (km <= urban) {
    return CoverageNotice(
      inside: true,
      text:
          'Dentro del radio urbano (${urban.toStringAsFixed(0)} km). Movilización sin recargo.',
    );
  }
  return CoverageNotice(
    inside: false,
    text:
        'Fuera del radio urbano (${km.toStringAsFixed(1)} km). Movilización $feeLabel.',
  );
}
