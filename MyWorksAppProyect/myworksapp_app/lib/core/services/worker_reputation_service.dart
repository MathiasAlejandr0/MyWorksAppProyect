import 'dart:math' as math;

import '../database/models/worker_model.dart';
import '../domain/catalog_order.dart';

/// Orden del marketplace y puntaje interno de reputación.
/// El listado usa el orden único del catálogo (cercanía, nota, precio);
/// `listingScore` queda para el modo inteligente y el panel de administración.
class WorkerReputationService {
  WorkerReputationService._();
  static final WorkerReputationService instance = WorkerReputationService._();

  static const double _penaltyPerRejection = 0.35;
  static const double _maxPenalty = 1.75;

  /// Puntaje interno para ordenar listados (mayor = más arriba).
  /// Misma regla que Postgres: `score_listado` ya incluye `prioridad_manual × 2`.
  double listingScore(WorkerModel worker) {
    final stored = worker.listingScore;
    if (stored != null) return stored;
    final penalty = math.min(
      worker.rejectionCount * _penaltyPerRejection,
      _maxPenalty,
    );
    return worker.rating - penalty + worker.manualPriority * 2.0;
  }

  /// Orden único del catálogo: cercanía, luego nota, luego precio.
  /// Mismo algoritmo que la RPC `listar_profesionales_catalogo` y la web
  /// (ver `core/domain/catalog_order.dart`).
  void sortForListing(
    List<WorkerModel> workers, {
    double? clientLatitude,
    double? clientLongitude,
  }) {
    sortCatalog(
      workers,
      (worker) => CatalogOrderItem(
        id: worker.userId,
        rating: worker.rating,
        price: worker.visitFee,
        latitude: worker.baseLatitude,
        longitude: worker.baseLongitude,
      ),
      originLatitude: clientLatitude,
      originLongitude: clientLongitude,
    );
  }
}
