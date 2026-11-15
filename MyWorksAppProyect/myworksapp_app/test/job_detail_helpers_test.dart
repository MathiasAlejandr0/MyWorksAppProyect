import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/jobs/presentation/utils/job_detail_helpers.dart';

JobModel _job({
  required String status,
  Map<String, dynamic>? serviceMetadata,
  Map<String, dynamic>? pricingSnapshot,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return JobModel(
    id: 'job-1',
    userId: 'user-1',
    serviceId: 'svc-1',
    status: status,
    address: 'Test',
    serviceMetadata: serviceMetadata,
    pricingSnapshot: pricingSnapshot,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('JobDetailHelpers.completionTargetStatus', () {
    test('invitación por tier → awaiting_client_approval', () {
      final job = _job(
        status: AppConstants.jobStatusInProgress,
        serviceMetadata: {'request_type': 'worker_tier_invitation'},
      );
      expect(
        JobDetailHelpers.completionTargetStatus(job),
        PricingConstants.jobAwaitingClientApproval,
      );
    });

    test('al finalizar, el cliente debe recibir conforme', () {
      final job = _job(status: AppConstants.jobStatusInProgress);
      expect(
        JobDetailHelpers.completionTargetStatus(job),
        PricingConstants.jobAwaitingClientApproval,
      );
    });
  });

  group('JobDetailHelpers.quoteFromJob', () {
    test('reconstruye el cobro desde metadatos si no hay snapshot', () {
      final job = _job(
        status: PricingConstants.jobAwaitingPayment,
        serviceMetadata: {
          'quoted_total_clp': 25000,
          'quoted_subtotal_clp': 25000,
          'quoted_fee_clp': 1250,
          'quoted_message': 'Visita',
        },
      );
      final quote = JobDetailHelpers.quoteFromJob(job);
      expect(quote, isNotNull);
      expect(quote!.totalClp, 25000);
      expect(quote.platformFeeClp, 1250);
      expect(quote.message, 'Visita');
    });

    test('usa la tarifa publicada del profesional si no hay quoted_*', () {
      final job = _job(
        status: PricingConstants.jobAwaitingPayment,
        serviceMetadata: {'worker_tier_price_clp': 18000},
      );
      expect(JobDetailHelpers.quoteFromJob(job)?.totalClp, 18000);
    });

    test('sin snapshot ni metadatos no inventa un cobro', () {
      final job = _job(status: PricingConstants.jobAwaitingPayment);
      expect(JobDetailHelpers.quoteFromJob(job), isNull);
    });
  });

  group('JobDetailHelpers.canOpenChat', () {
    test('abre en pendiente, en camino y en curso', () {
      expect(JobDetailHelpers.canOpenChat(AppConstants.jobStatusPending), isTrue);
      expect(JobDetailHelpers.canOpenChat(AppConstants.jobStatusEnRoute), isTrue);
      expect(JobDetailHelpers.canOpenChat(AppConstants.jobStatusInProgress), isTrue);
      expect(
        JobDetailHelpers.canOpenChat(PricingConstants.jobAwaitingClientApproval),
        isTrue,
      );
    });

    test('no abre en completado ni cancelado', () {
      expect(JobDetailHelpers.canOpenChat(AppConstants.jobStatusCompleted), isFalse);
      expect(JobDetailHelpers.canOpenChat(AppConstants.jobStatusCancelled), isFalse);
      expect(
        JobDetailHelpers.canOpenChat(PricingConstants.jobAwaitingPayment),
        isFalse,
      );
    });
  });
}
