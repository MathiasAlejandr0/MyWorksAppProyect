import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/job_price.dart';

void main() {
  test('prefiere el total del snapshot de precio', () {
    expect(
      agreedJobPriceClp(
        pricingSnapshot: {'total_clp': 45000, 'subtotal_clp': 40000},
        serviceMetadata: {'monto': 1000},
      ),
      45000,
    );
  });

  test('usa metadatos si el snapshot no trae un monto positivo', () {
    expect(
      agreedJobPriceClp(
        pricingSnapshot: {'total_clp': 0},
        serviceMetadata: {'monto_clp': 28000},
      ),
      28000,
    );
  });

  test('entiende totalClp en camelCase y quoted_total_clp', () {
    expect(agreedJobPriceClp(pricingSnapshot: {'totalClp': 56000}), 56000);
    expect(
      agreedJobPriceClp(pricingSnapshot: {'quoted_total_clp': 61000}),
      61000,
    );
  });

  test('usa el monto registrado de un pago si no hay snapshot', () {
    expect(agreedJobPriceClp(recordedAmountClp: 25000), 25000);
  });

  test('devuelve null cuando no hay precio real', () {
    expect(
      agreedJobPriceClp(
        pricingSnapshot: {'message': 'sin monto'},
        serviceMetadata: {'nota': 'cotizar'},
      ),
      isNull,
    );
  });
}
