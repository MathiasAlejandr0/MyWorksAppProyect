import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/services/payment_guard.dart';
import 'package:myworksapp/core/utils/constants.dart';

JobModel _job({
  required String status,
  String pricingMode = PricingConstants.modeOpenQuote,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return JobModel(
    id: 'job-1',
    userId: 'user-1',
    serviceId: 'svc-1',
    status: status,
    address: 'Test',
    pricingMode: pricingMode,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PaymentGuard.requiresAuthorizedForAccepted', () {
    test('open quote → accepted requiere pago previo', () {
      expect(
        PaymentGuard.requiresAuthorizedForAccepted(
          PricingConstants.modeOpenQuote,
          AppConstants.jobStatusAccepted,
        ),
        isTrue,
      );
    });

    test('fixed price → accepted no usa esta regla', () {
      expect(
        PaymentGuard.requiresAuthorizedForAccepted(
          PricingConstants.modeFixedPrice,
          AppConstants.jobStatusAccepted,
        ),
        isFalse,
      );
    });

    test('otro destino nunca requiere esta regla', () {
      expect(
        PaymentGuard.requiresAuthorizedForAccepted(
          PricingConstants.modeOpenQuote,
          AppConstants.jobStatusInProgress,
        ),
        isFalse,
      );
    });
  });

  group('PaymentGuard.fromAwaitingPaymentToAccepted', () {
    test('true cuando el trabajo espera pago y el destino es accepted', () {
      final job = _job(status: PricingConstants.jobAwaitingPayment);
      expect(
        PaymentGuard.fromAwaitingPaymentToAccepted(
          job,
          AppConstants.jobStatusAccepted,
        ),
        isTrue,
      );
    });

    test('false si el estado actual no es awaiting_payment', () {
      final job = _job(status: AppConstants.jobStatusPending);
      expect(
        PaymentGuard.fromAwaitingPaymentToAccepted(
          job,
          AppConstants.jobStatusAccepted,
        ),
        isFalse,
      );
    });

    test('false si el destino no es accepted', () {
      final job = _job(status: PricingConstants.jobAwaitingPayment);
      expect(
        PaymentGuard.fromAwaitingPaymentToAccepted(
          job,
          AppConstants.jobStatusInProgress,
        ),
        isFalse,
      );
    });
  });
}
