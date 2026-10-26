import 'dart:math' as math;

import '../database/models/worker_model.dart';
import '../domain/distance_match.dart';
import '../domain/worker_highlight.dart';

/// Orden de marketplace: usa el score del servidor si existe.
/// Si no, cae a nota pública menos penalización por rechazos.
class WorkerReputationService {
  WorkerReputationService._();
  static final WorkerReputationService instance = WorkerReputationService._();

  static const double _penaltyPerRejection = 0.35;
  static const double _maxPenalty = 1.75;

  /// Feed principal: reputación del servidor, más cerca primero, élite arriba
  /// y notas flojas (bajo 3.5) con menos peso. No esconde a quien ya pasó el piso.
  double feedScore(
    WorkerModel worker, {
    double? clientLatitude,
    double? clientLongitude,
  }) {
    var score = listingScore(worker);
    if (worker.rating > 0 && worker.rating < lowRatingDemote) {
      score *= 0.45;
    }
    if (isEliteWorker(worker)) score += 8;
    final baseLat = worker.baseLatitude;
    final baseLng = worker.baseLongitude;
    if (clientLatitude != null &&
        clientLongitude != null &&
        baseLat != null &&
        baseLng != null) {
      final km = haversineKm(baseLat, baseLng, clientLatitude, clientLongitude);
      if (km <= worker.urbanRadiusKm) {
        score += 12;
      } else {
        score -= math.min(km, 40) * 0.35;
      }
    }
    return score;
  }

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

  void sortForListing(
    List<WorkerModel> workers, {
    double? clientLatitude,
    double? clientLongitude,
  }) {
    workers.sort((a, b) {
      final byScore = feedScore(
        b,
        clientLatitude: clientLatitude,
        clientLongitude: clientLongitude,
      ).compareTo(feedScore(
        a,
        clientLatitude: clientLatitude,
        clientLongitude: clientLongitude,
      ));
      if (byScore != 0) return byScore;
      return a.userId.compareTo(b.userId);
    });
  }
}
