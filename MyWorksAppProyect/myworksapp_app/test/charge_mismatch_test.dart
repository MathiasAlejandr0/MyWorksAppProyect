import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/charge_mismatch.dart';
import 'package:myworksapp/core/domain/price_quote.dart';
import 'package:myworksapp/core/services/pricing_service.dart';

void main() {
  test('lee el monto que el servidor sí acepta', () {
    expect(
      expectedChargeFromMismatch(
        'Monto 40220 no coincide con tarifa/cotización 39830',
      ),
      39830,
    );
    expect(
      expectedChargeFromMismatch(
        'Monto 100 no coincide con tarifa/cotización esperada 90',
      ),
      90,
    );
    expect(expectedChargeFromMismatch('La tarjeta no quedó lista'), isNull);
  });

  test('alinea comisión y pago del profesional al total real', () {
    const original = PriceQuote(
      pricingMode: 'precio_fijo',
      subtotalClp: 40220,
      platformFeeClp: 2011,
      totalClp: 40220,
      workerPayoutClp: 38209,
    );
    final aligned =
        PricingService.instance.alignToChargedTotal(original, 39830);

    expect(aligned.totalClp, 39830);
    expect(aligned.platformFeeClp, 1992);
    expect(aligned.workerPayoutClp, 37838);
  });
}
