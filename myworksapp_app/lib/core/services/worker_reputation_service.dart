import 'dart:math' as math;

import '../database/models/worker_model.dart';

/// Penalización oculta por rechazos frecuentes (no visible en el perfil público).
class WorkerReputationService {
  WorkerReputationService._();
  static final WorkerReputationService instance = WorkerReputationService._();

  static const double _penaltyPerRejection = 0.35;
  static const double _maxPenalty = 1.75;

  /// Puntaje interno para ordenar listados (mayor = más arriba).
  double listingScore(WorkerModel worker) {
    final penalty = math.min(
      worker.rejectionCount * _penaltyPerRejection,
      _maxPenalty,
    );
    return worker.rating - penalty;
  }

  void sortForListing(List<WorkerModel> workers) {
    workers.sort(
      (a, b) => listingScore(b).compareTo(listingScore(a)),
    );
  }
}
