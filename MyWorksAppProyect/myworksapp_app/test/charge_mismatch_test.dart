import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/charge_mismatch.dart';
import 'package:myworksapp/core/domain/job_charge_preview.dart';
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
    expect(aligned.platformFeeClp + aligned.workerPayoutClp!, aligned.totalClp);
  });

  test('tarifa, traslado, comisión y neto cierran con el total cobrado', () {
    const original = PriceQuote(
      pricingMode: 'precio_fijo',
      subtotalClp: 40220,
      platformFeeClp: 2011,
      totalClp: 40220,
      workerPayoutClp: 38209,
      breakdown: {
        'base_clp': 30000,
        'transport_extra_clp': 10220,
      },
    );
    final aligned =
        PricingService.instance.alignToChargedTotal(original, 39829);
    final lines = PricingService.instance.workerChargeLines(aligned);

    expect(lines.serviceClp, 30000);
    expect(lines.transportClp, 9829);
    expect(lines.serviceClp! + lines.transportClp, lines.totalClp);
    expect(lines.totalClp, 39829);
    expect(lines.feeClp, 1991);
    expect(lines.payoutClp, 37838);
    expect(lines.feeClp + lines.payoutClp, lines.totalClp);
  });

  test('el resumen usa el traslado real y no pide una segunda confirmación',
      () {
    const shown = PriceQuote(
      pricingMode: 'precio_fijo',
      subtotalClp: 75219,
      platformFeeClp: 3761,
      totalClp: 75219,
      workerPayoutClp: 71458,
      breakdown: {
        'base_clp': 65000,
        'transport_extra_clp': 10219,
      },
    );
    const preview = JobChargePreview(
      totalClp: 74829,
      serviceClp: 65000,
      transportClp: 9829,
      feeClp: 3741,
      payoutClp: 71088,
    );

    final ready = PricingService.instance.applyServerCharge(shown, preview);
    final lines = PricingService.instance.workerChargeLines(ready);

    expect(lines.serviceClp, 65000);
    expect(lines.transportClp, 9829);
    expect(lines.serviceClp! + lines.transportClp, 74829);
    expect(lines.totalClp, 74829);
    expect(lines.feeClp, 3741);
    expect(lines.payoutClp, 71088);
    expect(lines.feeClp + lines.payoutClp, lines.totalClp);
    expect(ready.totalClp, preview.totalClp);
  });

  test('la comisión no supera el bruto y coincide con el 5 % redondeado', () {
    final pricing = PricingService.instance;
    expect(pricing.serviceFeeFor(0), 0);
    expect(pricing.serviceFeeFor(500), 500);
    expect(pricing.serviceFeeFor(39829), 1991);
    expect(pricing.serviceFeeFor(39830), 1992);
  });
}
