import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/domain/price_quote.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/utils/job_display_utils.dart';

JobModel _job({
  Map<String, dynamic>? serviceMetadata,
  Map<String, dynamic>? pricingSnapshot,
  String? serviceSkuId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return JobModel(
    id: 'job-1',
    userId: 'user-1',
    serviceId: 'svc-1',
    status: 'pendiente',
    address: 'Test',
    serviceMetadata: serviceMetadata,
    pricingSnapshot: pricingSnapshot,
    serviceSkuId: serviceSkuId,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('JobDisplayUtils', () {
    test('usa etiqueta y tarifa desde metadatos del tier', () {
      final job = _job(
        serviceMetadata: {
          'worker_tier_label': 'Pintura por dormitorio',
          'worker_tier_price_clp': 45000,
        },
      );

      expect(JobDisplayUtils.title(job), 'Pintura por dormitorio');
      expect(JobDisplayUtils.priceLine(job), contains('45'));
    });

    test('usa snapshot de cotización cuando no hay precio en metadatos', () {
      final job = _job(
        pricingSnapshot: const PriceQuote(
          pricingMode: PricingConstants.modeFixedPrice,
          totalClp: 82000,
          subtotalClp: 82000,
          message: 'Instalación eléctrica certificada',
        ).toJson(),
      );

      expect(JobDisplayUtils.title(job), 'Instalación eléctrica certificada');
      expect(JobDisplayUtils.priceLine(job), contains('82'));
    });
  });
}
