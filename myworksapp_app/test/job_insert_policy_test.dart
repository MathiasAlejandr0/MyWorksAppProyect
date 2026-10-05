import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/job_insert_policy.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/utils/constants.dart';

void main() {
  test('con profesional el alta es esperando pago, no pendiente', () {
    expect(
      jobInsertMatchesPolicy(
        workerId: 'pro-1',
        status: PricingConstants.jobAwaitingPayment,
      ),
      isTrue,
    );
    expect(
      jobInsertMatchesPolicy(
        workerId: 'pro-1',
        status: AppConstants.jobStatusPending,
      ),
      isFalse,
    );
    expect(PricingConstants.jobAwaitingPayment, 'esperando_pago');
  });

  test('sin profesional solo nace pendiente o esperando cotizaciones', () {
    expect(
      jobInsertMatchesPolicy(
        workerId: null,
        status: AppConstants.jobStatusPending,
      ),
      isTrue,
    );
    expect(
      jobInsertMatchesPolicy(
        workerId: '',
        status: PricingConstants.jobAwaitingQuotes,
      ),
      isTrue,
    );
    expect(
      jobInsertMatchesPolicy(
        workerId: null,
        status: PricingConstants.jobAwaitingPayment,
      ),
      isFalse,
    );
  });

  test('con profesional también cabe una cotización abierta', () {
    expect(
      jobInsertMatchesPolicy(
        workerId: 'pro-1',
        status: PricingConstants.jobAwaitingQuotes,
      ),
      isTrue,
    );
  });
}
