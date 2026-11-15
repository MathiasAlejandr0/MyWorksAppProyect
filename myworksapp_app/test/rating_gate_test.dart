import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/ratings/domain/rating_gate.dart';

void main() {
  test('el cliente califica al profesional en un trabajo terminado', () {
    expect(
      ratingBlockReason(
        currentUserId: 'cliente',
        jobClientId: 'cliente',
        jobWorkerId: 'pro',
        jobStatus: 'completado',
        alreadyRated: false,
        disputeOpen: false,
        direction: RatingDirection.clientToWorker,
      ),
      isNull,
    );
  });

  test('el profesional califica al cliente en un trabajo terminado', () {
    expect(
      ratingBlockReason(
        currentUserId: 'pro',
        jobClientId: 'cliente',
        jobWorkerId: 'pro',
        jobStatus: 'completado',
        alreadyRated: false,
        disputeOpen: false,
        direction: RatingDirection.workerToClient,
      ),
      isNull,
    );
  });

  test(
      'cada dirección se bloquea si no es la parte, está incompleto o hay disputa',
      () {
    expect(
      ratingBlockReason(
        currentUserId: 'pro',
        jobClientId: 'cliente',
        jobWorkerId: 'pro',
        jobStatus: 'completado',
        alreadyRated: false,
        disputeOpen: false,
        direction: RatingDirection.clientToWorker,
      ),
      contains('profesional'),
    );
    expect(
      ratingBlockReason(
        currentUserId: 'cliente',
        jobClientId: 'cliente',
        jobWorkerId: 'pro',
        jobStatus: 'completado',
        alreadyRated: false,
        disputeOpen: false,
        direction: RatingDirection.workerToClient,
      ),
      contains('profesional'),
    );
    expect(
      ratingBlockReason(
        currentUserId: 'pro',
        jobClientId: 'cliente',
        jobWorkerId: 'pro',
        jobStatus: 'en_curso',
        alreadyRated: false,
        disputeOpen: false,
        direction: RatingDirection.workerToClient,
      ),
      contains('terminado'),
    );
    expect(
      ratingBlockReason(
        currentUserId: 'pro',
        jobClientId: 'cliente',
        jobWorkerId: 'pro',
        jobStatus: 'completado',
        alreadyRated: false,
        disputeOpen: true,
        direction: RatingDirection.workerToClient,
      ),
      contains('disputa'),
    );
    expect(
      ratingBlockReason(
        currentUserId: 'pro',
        jobClientId: 'cliente',
        jobWorkerId: 'pro',
        jobStatus: 'completado',
        alreadyRated: true,
        disputeOpen: false,
        direction: RatingDirection.workerToClient,
      ),
      contains('Ya calificaste'),
    );
  });
}
