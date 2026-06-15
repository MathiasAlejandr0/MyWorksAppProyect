import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/services/job_transition_matrix.dart';
import 'package:myworksapp/core/utils/constants.dart';

void main() {
  group('JobTransitionMatrix', () {
    test('legacy: pending puede ir a accepted o cancelled', () {
      expect(
        JobTransitionMatrix.isAllowed(
          PricingConstants.modeLegacy,
          AppConstants.jobStatusPending,
          AppConstants.jobStatusAccepted,
        ),
        isTrue,
      );
      expect(
        JobTransitionMatrix.isAllowed(
          PricingConstants.modeLegacy,
          AppConstants.jobStatusPending,
          AppConstants.jobStatusCompleted,
        ),
        isFalse,
      );
    });

    test('fixed price: requiere awaiting_payment antes de accepted', () {
      expect(
        JobTransitionMatrix.isAllowed(
          PricingConstants.modeFixedPrice,
          PricingConstants.jobAwaitingPayment,
          AppConstants.jobStatusAccepted,
        ),
        isTrue,
      );
    });

    test('completed no tiene transiciones salientes', () {
      expect(
        JobTransitionMatrix.allowedTargets(
          PricingConstants.modeLegacy,
          AppConstants.jobStatusCompleted,
        ),
        isEmpty,
      );
    });
  });
}
