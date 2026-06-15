import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/jobs/presentation/utils/job_detail_helpers.dart';

JobModel _job({
  required String status,
  Map<String, dynamic>? serviceMetadata,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return JobModel(
    id: 'job-1',
    userId: 'user-1',
    serviceId: 'svc-1',
    status: status,
    address: 'Test',
    serviceMetadata: serviceMetadata,
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

    test('trabajo normal → completed', () {
      final job = _job(status: AppConstants.jobStatusInProgress);
      expect(
        JobDetailHelpers.completionTargetStatus(job),
        AppConstants.jobStatusCompleted,
      );
    });
  });
}
