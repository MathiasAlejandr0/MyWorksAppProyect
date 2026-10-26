import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/domain/worker_highlight.dart';
import 'package:myworksapp/core/services/worker_reputation_service.dart';

WorkerModel _worker({
  required String id,
  double rating = 4.5,
  int completed = 2,
  bool elite = false,
  double? lat,
  double? lng,
  double urban = 5,
  int outsideFee = 6000,
  double? score,
}) {
  return WorkerModel(
    userId: id,
    profession: 'Gasfíter',
    rating: rating,
    completedJobs: completed,
    isElite: elite,
    baseLatitude: lat,
    baseLongitude: lng,
    urbanRadiusKm: urban,
    outsideMobilizationFeeClp: outsideFee,
    listingScore: score,
  );
}

void main() {
  test('élite exige nota alta y volumen, o la marca del servidor', () {
    expect(
      isEliteWorker(_worker(id: 'a', rating: 4.9, completed: 5)),
      isTrue,
    );
    expect(
      isEliteWorker(_worker(id: 'b', rating: 4.9, completed: 2)),
      isFalse,
    );
    expect(
      isEliteWorker(_worker(id: 'c', rating: 3, completed: 1, elite: true)),
      isTrue,
    );
  });

  test('el aviso distingue dentro y fuera del radio urbano', () {
    final worker = _worker(
      id: 'pm',
      lat: -41.4718,
      lng: -72.9396,
      urban: 5,
      outsideFee: 7000,
    );
    final inside = coverageNotice(
      worker: worker,
      clientLatitude: -41.469,
      clientLongitude: -72.941,
    );
    final outside = coverageNotice(
      worker: worker,
      clientLatitude: -41.3195,
      clientLongitude: -72.9854,
    );
    expect(inside.inside, isTrue);
    expect(inside.text, contains('sin recargo'));
    expect(outside.inside, isFalse);
    expect(outside.text, contains('7.000'));
  });

  test('el feed sube a la élite cercana y baja la nota floja', () {
    final eliteNear = _worker(
      id: 'elite',
      rating: 4.9,
      completed: 8,
      lat: -41.4718,
      lng: -72.9396,
      score: 70,
    );
    final far = _worker(
      id: 'far',
      rating: 4.9,
      completed: 9,
      lat: -41.3195,
      lng: -72.9854,
      score: 72,
    );
    final weak = _worker(
      id: 'weak',
      rating: 3.2,
      completed: 4,
      lat: -41.47,
      lng: -72.94,
      score: 80,
    );
    final ordered = [far, weak, eliteNear];
    WorkerReputationService.instance.sortForListing(
      ordered,
      clientLatitude: -41.4718,
      clientLongitude: -72.9396,
    );
    expect(ordered.first.userId, 'elite');
    expect(ordered.last.userId, 'weak');
  });
}
