import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/database/models/payment_model.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/services/payment_guard.dart';
import 'package:myworksapp/core/services/payment_guard_ports.dart';
import 'package:myworksapp/core/utils/app_error.dart';
import 'package:myworksapp/core/utils/constants.dart';

JobModel _job({
  required String status,
  String pricingMode = PricingConstants.modeFixedPrice,
  Map<String, dynamic>? serviceMetadata,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return JobModel(
    id: 'job-1',
    userId: 'user-1',
    serviceId: 'svc-1',
    status: status,
    address: 'Test',
    pricingMode: pricingMode,
    serviceMetadata: serviceMetadata,
    createdAt: now,
    updatedAt: now,
  );
}

PaymentModel _authorizedPayment() {
  final now = DateTime.utc(2026, 1, 1);
  return PaymentModel(
    id: 'pay-1',
    jobId: 'job-1',
    amount: 10000,
    status: 'authorized',
    createdAt: now,
    updatedAt: now,
  );
}

PaymentGuardPorts _ports({
  PaymentModel? primaryPayment,
  bool hasAuthorized = false,
  int pendingChangeOrders = 0,
  int approvedUnpaid = 0,
}) {
  return PaymentGuardPorts(
    getPrimaryPayment: (_) async => primaryPayment,
    hasAuthorizedPrimaryPayment: (_) async => hasAuthorized,
    countPendingChangeOrders: (_) async => pendingChangeOrders,
    countApprovedUnpaidChangeOrders: (_) async => approvedUnpaid,
  );
}

void main() {
  group('PaymentGuard.validate', () {
    test('in_progress exige pago autorizado en modalidad con escrow', () async {
      final job = _job(
        status: AppConstants.jobStatusAccepted,
        pricingMode: PricingConstants.modeFixedPrice,
      );

      await expectLater(
        PaymentGuard.validate(
          job: job,
          targetStatus: AppConstants.jobStatusInProgress,
          ports: _ports(),
        ),
        throwsA(
          isA<AppError>().having(
            (e) => e.message,
            'message',
            contains('pago en garantía'),
          ),
        ),
      );
    });

    test('in_progress permite transición con pago autorizado', () async {
      final job = _job(
        status: AppConstants.jobStatusAccepted,
        pricingMode: PricingConstants.modeFixedPrice,
      );

      await PaymentGuard.validate(
        job: job,
        targetStatus: AppConstants.jobStatusInProgress,
        ports: _ports(primaryPayment: _authorizedPayment()),
      );
    });

    test('in_progress rechaza si hay órdenes de cambio pendientes', () async {
      final job = _job(
        status: AppConstants.jobStatusAccepted,
        pricingMode: PricingConstants.modeFixedPrice,
      );

      await expectLater(
        PaymentGuard.validate(
          job: job,
          targetStatus: AppConstants.jobStatusInProgress,
          ports: _ports(
            primaryPayment: _authorizedPayment(),
            pendingChangeOrders: 1,
          ),
        ),
        throwsA(
          isA<AppError>().having(
            (e) => e.message,
            'message',
            contains('órdenes de cambio pendientes'),
          ),
        ),
      );
    });

    test('completed rechaza órdenes de cambio sin resolver', () async {
      final job = _job(
        status: AppConstants.jobStatusInProgress,
        pricingMode: PricingConstants.modeFixedPrice,
      );

      await expectLater(
        PaymentGuard.validate(
          job: job,
          targetStatus: AppConstants.jobStatusCompleted,
          ports: _ports(
            primaryPayment: _authorizedPayment(),
            pendingChangeOrders: 2,
          ),
        ),
        throwsA(
          isA<AppError>().having(
            (e) => e.message,
            'message',
            contains('órdenes de cambio sin resolver'),
          ),
        ),
      );
    });

    test('tier invitation exige pago al completar desde awaiting_client_approval',
        () async {
      final job = _job(
        status: PricingConstants.jobAwaitingClientApproval,
        pricingMode: PricingConstants.modeLegacy,
        serviceMetadata: {'request_type': 'worker_tier_invitation'},
      );

      await expectLater(
        PaymentGuard.validate(
          job: job,
          targetStatus: AppConstants.jobStatusCompleted,
          ports: _ports(hasAuthorized: false),
        ),
        throwsA(
          isA<AppError>().having(
            (e) => e.message,
            'message',
            contains('completar el pago'),
          ),
        ),
      );
    });

    test('awaiting_payment → accepted exige pago autorizado', () async {
      final job = _job(
        status: PricingConstants.jobAwaitingPayment,
        pricingMode: PricingConstants.modeFixedPrice,
      );

      await expectLater(
        PaymentGuard.validate(
          job: job,
          targetStatus: AppConstants.jobStatusAccepted,
          ports: _ports(),
        ),
        throwsA(
          isA<AppError>().having(
            (e) => e.message,
            'message',
            contains('Confirma el pago'),
          ),
        ),
      );
    });
  });
}
