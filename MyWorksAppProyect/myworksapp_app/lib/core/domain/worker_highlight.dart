import 'transport_surcharge.dart';
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

/// Misma regla que el cobro: radio de servicio, extra por km fuera.
CoverageNotice coverageNotice({
  required WorkerModel worker,
  double? clientLatitude,
  double? clientLongitude,
}) {
  final radiusKm = resolveServiceRadiusKm(worker.serviceRadiusKm);
  final quote = transportSurcharge(
    workerLat: worker.baseLatitude,
    workerLng: worker.baseLongitude,
    jobLat: clientLatitude,
    jobLng: clientLongitude,
    radiusKm: worker.serviceRadiusKm,
  );
  if (quote.insideRadar == null) {
    return CoverageNotice(
      inside: null,
      text:
          'Hasta ${radiusKm.round()} km sin extra de traslado. Más lejos, recargo por km.',
    );
  }
  if (quote.insideRadar == true) {
    return CoverageNotice(
      inside: true,
      text: 'Dentro de ${radiusKm.round()} km: sin extra de traslado.',
    );
  }
  final km = quote.distanceKm?.toStringAsFixed(1) ?? '?';
  return CoverageNotice(
    inside: false,
    text: 'Fuera del área ($km km): +${_clp(quote.extraClp)} de traslado.',
  );
}
