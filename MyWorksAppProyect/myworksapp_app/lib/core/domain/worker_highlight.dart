import 'transport_surcharge.dart';
import '../database/models/worker_model.dart';

/// Destacado del mes: misma regla que `trabajadores.es_elite` en Postgres.
const double eliteMinRating = 4.7;
const int eliteMinCompletedJobs = 5;

/// Bajo este piso el catálogo no lo muestra. Entre 3.0 y 3.5 sigue, más abajo.
const double lowRatingFloor = 3.0;
const double lowRatingDemote = 3.5;

/// Filtro de nota mínima del listado. Un profesional sin reseñas no tiene
/// una nota baja: tiene «Nuevo». Con el piso por defecto (3+) se muestra,
/// igual que en `listar_profesionales_catalogo`; si el cliente pide una nota
/// más alta, solo entran los que ya la tienen con reseñas reales.
bool passesMinRating(double rating, double minRating) {
  if (rating <= 0) return minRating <= lowRatingFloor;
  return rating >= minRating;
}

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

/// Radio de servicio. El monto del traslado se confirma en el cobro.
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
    text: 'Fuera del área ($km km). El traslado se confirma al pagar.',
  );
}
