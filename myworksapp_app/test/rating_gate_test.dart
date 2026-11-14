import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/ratings/domain/rating_gate.dart';

void main() {
  test('el cliente califica un trabajo terminado sin disputa', () {
    expect(
      ratingBlockReason(
        currentUserId: 'cliente',
        jobClientId: 'cliente',
        jobStatus: 'completado',
        alreadyRated: false,
        disputeOpen: false,
      ),
      isNull,
    );
  });

  test('bloquea ajeno, incompleto, duplicado y disputa', () {
    expect(
      ratingBlockReason(
        currentUserId: 'otro',
        jobClientId: 'cliente',
        jobStatus: 'completado',
        alreadyRated: false,
        disputeOpen: false,
      ),
      contains('cliente'),
    );
    expect(
      ratingBlockReason(
        currentUserId: 'cliente',
        jobClientId: 'cliente',
        jobStatus: 'en_curso',
        alreadyRated: false,
        disputeOpen: false,
      ),
      contains('terminado'),
    );
    expect(
      ratingBlockReason(
        currentUserId: 'cliente',
        jobClientId: 'cliente',
        jobStatus: 'completado',
        alreadyRated: true,
        disputeOpen: false,
      ),
      contains('ya tiene'),
    );
    expect(
      ratingBlockReason(
        currentUserId: 'cliente',
        jobClientId: 'cliente',
        jobStatus: 'completado',
        alreadyRated: false,
        disputeOpen: true,
      ),
      contains('disputa'),
    );
  });
}
