import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/core/utils/worker_job_status.dart';

JobModel _job(String status) {
  final now = DateTime.utc(2026, 1, 1);
  return JobModel(
    id: 'job-$status',
    userId: 'user-1',
    workerId: 'worker-1',
    serviceId: 'svc-1',
    status: status,
    address: 'Test',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('WorkerJobStatus', () {
    test('isActive incluye awaiting_payment y paused_change_order', () {
      expect(WorkerJobStatus.isActive(PricingConstants.jobAwaitingPayment), isTrue);
      expect(WorkerJobStatus.isActive(PricingConstants.jobPausedChangeOrder), isTrue);
      expect(WorkerJobStatus.isActive(AppConstants.jobStatusCompleted), isFalse);
    });

    test('pickHighlightJob prioriza in_progress', () {
      final jobs = [
        _job(PricingConstants.jobAwaitingPayment),
        _job(AppConstants.jobStatusInProgress),
        _job(AppConstants.jobStatusAccepted),
      ];
      expect(
        WorkerJobStatus.pickHighlightJob(jobs)?.status,
        AppConstants.jobStatusInProgress,
      );
    });

    test('activeBannerTitle para awaiting_payment', () {
      expect(
        WorkerJobStatus.activeBannerTitle(PricingConstants.jobAwaitingPayment),
        'Esperando pago del cliente',
      );
    });
  });
}
