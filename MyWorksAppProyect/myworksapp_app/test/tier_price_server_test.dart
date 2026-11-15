import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/pricing_service.dart';

void main() {
  test('la invitación por tarifa cobra el precio publicado, sin recargo de comuna', () {
    final quote = PricingService.instance.calculateWorkerTierPrice(
      optionId: 'plumbing_minor',
      optionLabel: 'Arreglo menor',
      amountClp: 28000,
      comunaKey: 'providencia',
    );
    expect(quote.totalClp, 28000);
    expect(quote.subtotalClp, 28000);
  });

  test('fuera del radar suma traslado y cerca no cobra extra', () {
    final far = PricingService.instance.calculateWorkerTierPrice(
      optionId: 'plumbing_minor',
      optionLabel: 'Arreglo menor',
      amountClp: 28000,
      transportExtraClp: 6000,
    );
    expect(far.totalClp, 34000);
    expect(far.breakdown['transport_extra_clp'], 6000);

    final near = PricingService.instance.calculateWorkerTierPrice(
      optionId: 'plumbing_minor',
      optionLabel: 'Arreglo menor',
      amountClp: 28000,
      transportExtraClp: 0,
    );
    expect(near.totalClp, 28000);
  });
}
