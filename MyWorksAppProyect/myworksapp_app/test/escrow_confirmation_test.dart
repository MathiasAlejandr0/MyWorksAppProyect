import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/escrow_confirmation.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/utils/constants.dart';

void main() {
  test('confirmar el pago retenido por segunda vez no es un error', () {
    expect(escrowHoldAlreadyConfirmed(AppConstants.jobStatusPending), isTrue);
    expect(
      escrowHoldAlreadyConfirmed(PricingConstants.jobAwaitingClientApproval),
      isTrue,
    );
    expect(
      escrowHoldAlreadyConfirmed(PricingConstants.jobAwaitingPayment),
      isFalse,
    );
  });

  test('la conformidad solo cuenta como hecha cuando el trabajo cerró', () {
    expect(escrowReleaseAlreadyConfirmed(AppConstants.jobStatusCompleted), isTrue);
    expect(
      escrowReleaseAlreadyConfirmed(PricingConstants.jobAwaitingClientApproval),
      isFalse,
    );
  });
}
