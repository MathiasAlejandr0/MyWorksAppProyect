// GENERADO por scripts/cobertura/gen_calls.py. No editar a mano.
// Tests de humo: cada método público se llama contra el backend Supabase
// falso (test/support/fake_supabase.dart) en varios escenarios. Nada sale a
// la red: no toca producción ni Transbank.
// ignore_for_file: avoid_dynamic_calls, unnecessary_cast, prefer_const_constructors
// ignore_for_file: deprecated_member_use, unused_import, invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member, prefer_single_quotes
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:myworksapp/core/database/models/abuse_event_model.dart' as f0;
import 'package:myworksapp/core/database/models/analytics_event_model.dart'
    as f1;
import 'package:myworksapp/core/database/models/app_error_log_model.dart' as f2;
import 'package:myworksapp/core/database/models/boost_model.dart' as f3;
import 'package:myworksapp/core/database/models/change_order_model.dart' as f4;
import 'package:myworksapp/core/database/models/dispute_model.dart' as f5;
import 'package:myworksapp/core/database/models/feature_flag_model.dart' as f6;
import 'package:myworksapp/core/database/models/job_cancellation_model.dart'
    as f7;
import 'package:myworksapp/core/database/models/job_model.dart' as f8;
import 'package:myworksapp/core/database/models/job_photo_model.dart' as f9;
import 'package:myworksapp/core/database/models/message_model.dart' as f10;
import 'package:myworksapp/core/database/models/notification_model.dart' as f11;
import 'package:myworksapp/core/database/models/payment_model.dart' as f12;
import 'package:myworksapp/core/database/models/pending_action_model.dart'
    as f13;
import 'package:myworksapp/core/database/models/portfolio_model.dart' as f14;
import 'package:myworksapp/core/database/models/quote_proposal_model.dart'
    as f15;
import 'package:myworksapp/core/database/models/ranking_models.dart' as f16;
import 'package:myworksapp/core/database/models/rating_model.dart' as f17;
import 'package:myworksapp/core/database/models/report_model.dart' as f18;
import 'package:myworksapp/core/database/models/service_config_model.dart'
    as f19;
import 'package:myworksapp/core/database/models/service_model.dart' as f20;
import 'package:myworksapp/core/database/models/subscription_model.dart' as f21;
import 'package:myworksapp/core/database/models/user_block_model.dart' as f22;
import 'package:myworksapp/core/database/models/user_consent_model.dart' as f23;
import 'package:myworksapp/core/database/models/user_model.dart' as f24;
import 'package:myworksapp/core/database/models/worker_model.dart' as f25;
import 'package:myworksapp/core/domain/worker_custom_service.dart' as f26;
import 'package:myworksapp/core/domain/worker_hours.dart' as f27;
import 'package:myworksapp/core/database/models/worker_review_model.dart'
    as f28;
import 'package:myworksapp/core/database/repositories/abuse_repository.dart'
    as f29;
import 'package:myworksapp/core/database/repositories/admin/admin_catalog_repository.dart'
    as f30;
import 'package:myworksapp/core/database/repositories/admin/admin_incidents_repository.dart'
    as f31;
import 'package:myworksapp/core/database/repositories/admin/admin_jobs_repository.dart'
    as f32;
import 'package:myworksapp/core/database/repositories/admin/admin_metrics_repository.dart'
    as f33;
import 'package:myworksapp/core/database/repositories/admin/admin_models.dart'
    as f34;
import 'package:myworksapp/core/database/repositories/admin/admin_users_repository.dart'
    as f35;
import 'package:myworksapp/core/database/repositories/admin_repository.dart'
    as f36;
import 'package:myworksapp/core/database/repositories/analytics_repository.dart'
    as f37;
import 'package:myworksapp/core/database/repositories/app_error_log_repository.dart'
    as f38;
import 'package:myworksapp/core/database/repositories/boost_repository.dart'
    as f39;
import 'package:myworksapp/core/database/repositories/change_order_repository.dart'
    as f40;
import 'package:myworksapp/core/database/repositories/client_rating_repository.dart'
    as f41;
import 'package:myworksapp/core/database/repositories/dispute_repository.dart'
    as f42;
import 'package:myworksapp/core/database/repositories/feature_flag_repository.dart'
    as f43;
import 'package:myworksapp/core/database/repositories/job_cancellation_repository.dart'
    as f44;
import 'package:myworksapp/core/database/repositories/job_photo_repository.dart'
    as f45;
import 'package:myworksapp/core/database/repositories/job_repository.dart'
    as f46;
import 'package:myworksapp/core/database/repositories/message_repository.dart'
    as f47;
import 'package:myworksapp/core/database/repositories/notification_repository.dart'
    as f48;
import 'package:myworksapp/core/database/repositories/payment_repository.dart'
    as f49;
import 'package:myworksapp/core/database/repositories/payout_repository.dart'
    as f50;
import 'package:myworksapp/core/database/repositories/pending_action_repository.dart'
    as f51;
import 'package:myworksapp/core/database/repositories/portfolio_repository.dart'
    as f52;
import 'package:myworksapp/core/database/repositories/quote_proposal_repository.dart'
    as f53;
import 'package:myworksapp/core/database/repositories/ranking_repository.dart'
    as f54;
import 'package:myworksapp/core/database/repositories/rating_repository.dart'
    as f55;
import 'package:myworksapp/core/database/repositories/report_repository.dart'
    as f56;
import 'package:myworksapp/core/database/repositories/reschedule_repository.dart'
    as f57;
import 'package:myworksapp/core/database/repositories/service_config_repository.dart'
    as f58;
import 'package:myworksapp/core/database/repositories/service_repository.dart'
    as f59;
import 'package:myworksapp/core/database/repositories/subscription_repository.dart'
    as f60;
import 'package:myworksapp/core/database/repositories/user_block_repository.dart'
    as f61;
import 'package:myworksapp/core/database/repositories/user_consent_repository.dart'
    as f62;
import 'package:myworksapp/core/database/repositories/user_repository.dart'
    as f63;
import 'package:myworksapp/core/database/repositories/verification_event_repository.dart'
    as f64;
import 'package:myworksapp/core/database/repositories/worker_repository.dart'
    as f65;
import 'package:myworksapp/core/domain/user_location_context.dart' as f66;
import 'package:myworksapp/core/database/repositories/worker_schedule_repository.dart'
    as f67;
import 'package:myworksapp/core/domain/weekly_schedule.dart' as f68;
import 'package:myworksapp/core/database/repositories/worker_service_repository.dart'
    as f69;
import 'support/model_samples.dart';
import 'support/scenarios.dart';

void main() {
  setUpAll(setUpScenarios);
  test('AbuseEventModel (core/database/models/abuse_event_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f0.AbuseEventModel.fromMap(sampleAbuseEventModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            userId: 'id-1',
            abuseType: 'id-1',
            count: 1,
            detectedAt: DateTime.utc(2026, 1, 2, 15),
            actionTaken: 'id-1',
            actionTakenAt: DateTime.utc(2026, 1, 2, 15),
            isResolved: true));
      }
    });
  });
  test('AnalyticsEventModel (core/database/models/analytics_event_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(
          () => f1.AnalyticsEventModel.fromMap(sampleAnalyticsEventModel));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('AppErrorLogModel (core/database/models/app_error_log_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f2.AppErrorLogModel.fromMap(sampleAppErrorLogModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(status: 'id-1'));
      }
    });
  });
  test('BoostModel (core/database/models/boost_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f3.BoostModel.fromMap(sampleBoostModel));
      if (o != null) {
        await call(() => o.isActive);
        await call(() => o.toMap());
      }
    });
  });
  test('ChangeOrderModel (core/database/models/change_order_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f4.ChangeOrderModel.fromMap(sampleChangeOrderModel));
      if (o != null) {
        await call(() => o.isPendingClient);
        await call(() => o.isPaid);
        await call(() => o.toMap());
      }
    });
  });
  test('DisputeModel (core/database/models/dispute_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f5.DisputeModel.fromMap(sampleDisputeModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            jobId: 'id-1',
            openedBy: 'id-1',
            reason: 'id-1',
            description: 'id-1',
            status: 'id-1',
            resolution: 'id-1',
            resolvedBy: 'id-1',
            resolvedAt: DateTime.utc(2026, 1, 2, 15),
            createdAt: DateTime.utc(2026, 1, 2, 15),
            updatedAt: DateTime.utc(2026, 1, 2, 15)));
      }
    });
  });
  test('FeatureFlagModel (core/database/models/feature_flag_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f6.FeatureFlagModel.fromMap(sampleFeatureFlagModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            flagName: 'id-1',
            isEnabled: true,
            appVersion: 'id-1',
            role: 'id-1',
            userId: 'id-1',
            createdAt: DateTime.utc(2026, 1, 2, 15),
            updatedAt: DateTime.utc(2026, 1, 2, 15)));
      }
    });
  });
  test(
      'JobCancellationModel (core/database/models/job_cancellation_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(
          () => f7.JobCancellationModel.fromMap(sampleJobCancellationModel));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('JobModel (core/database/models/job_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f8.JobModel.fromMap(sampleJobModel));
      if (o != null) {
        await call(() => o.requiresEscrow);
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            userId: 'id-1',
            workerId: 'id-1',
            serviceId: 'id-1',
            status: 'id-1',
            address: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            description: 'id-1',
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            serviceMetadata: const {},
            pricingMode: 'id-1',
            paymentStatus: 'id-1',
            comunaId: 'id-1',
            pricingSnapshot: const {},
            serviceSkuId: 'id-1',
            hourlyBlockHours: 1,
            selectedQuoteId: 'id-1',
            createdAt: DateTime.utc(2026, 1, 2, 15),
            updatedAt: DateTime.utc(2026, 1, 2, 15),
            recordedAmountClp: 1));
      }
    });
  });
  test('JobPhotoModel (core/database/models/job_photo_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f9.JobPhotoModel.fromMap(sampleJobPhotoModel));
      if (o != null) {
        await call(() => o.isVideo);
        await call(() => o.hasRenderablePhoto);
        await call(() => o.toMap());
      }
    });
  });
  test('MessageModel (core/database/models/message_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f10.MessageModel.fromMap(sampleMessageModel));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('NotificationModel (core/database/models/notification_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f11.NotificationModel.fromMap(sampleNotificationModel));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('PaymentModel (core/database/models/payment_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f12.PaymentModel.fromMap(samplePaymentModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            jobId: 'id-1',
            changeOrderId: 'id-1',
            paymentType: 'id-1',
            amount: 1.0,
            currency: 'id-1',
            status: 'id-1',
            paymentMethod: 'id-1',
            transactionId: 'id-1',
            authorizedAt: DateTime.utc(2026, 1, 2, 15),
            releasedAt: DateTime.utc(2026, 1, 2, 15),
            refundedAt: DateTime.utc(2026, 1, 2, 15),
            createdAt: DateTime.utc(2026, 1, 2, 15),
            updatedAt: DateTime.utc(2026, 1, 2, 15)));
      }
    });
  });
  test('PendingActionModel (core/database/models/pending_action_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f13.PendingActionModel.fromMap(samplePendingActionModel));
      if (o != null) {
        await call(() => o.isPending);
        await call(() => o.isSyncing);
        await call(() => o.isSynced);
        await call(() => o.hasFailed);
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            userId: 'id-1',
            actionType: 'id-1',
            entityType: 'id-1',
            entityId: 'id-1',
            data: 'id-1',
            status: 'id-1',
            retryCount: 1,
            errorMessage: 'id-1',
            createdAt: DateTime.utc(2026, 1, 2, 15),
            updatedAt: DateTime.utc(2026, 1, 2, 15)));
      }
    });
  });
  test('PortfolioModel (core/database/models/portfolio_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f14.PortfolioModel.fromMap(samplePortfolioModel));
      if (o != null) {
        await call(() => o.isDemoAsset);
        await call(() => o.isVideo);
        await call(() => o.toMap());
      }
    });
  });
  test('QuoteProposalModel (core/database/models/quote_proposal_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f15.QuoteProposalModel.fromMap(sampleQuoteProposalModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.itemRows());
      }
    });
  });
  test('RankingConfig (core/database/models/ranking_models.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f16.RankingConfig.fromMap(sampleRankingConfig));
      if (o != null) {
        await call(() => o.toRpcMap());
        await call(() => o.copyWith(
            pesoCalificacion: 1.0,
            pesoCompletados: 1.0,
            pesoRechazos: 1.0,
            pesoVerificacion: 1.0,
            pesoImpulso: 1.0,
            pesoRecencia: 1.0,
            pesoConfianza: 1.0,
            priorBayes: 1.0,
            nBayes: 1.0,
            umbralRevision: 1.0,
            umbralAutoExcluir: 1.0,
            aprendizajeActivo: true,
            tasaAprendizaje: 1.0,
            pesosSenal: const {}));
      }
    });
  });
  test('ReviewSignal (core/database/models/ranking_models.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f16.ReviewSignal.fromMap(sampleReviewSignal));
      if (o != null) {
        await call(() => o.signalLabel);
      }
    });
  });
  test('RatingModel (core/database/models/rating_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f17.RatingModel.fromMap(sampleRatingModel));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('ReportModel (core/database/models/report_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f18.ReportModel.fromMap(sampleReportModel));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('ServiceConfigModel (core/database/models/service_config_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f19.ServiceConfigModel.fromMap(sampleServiceConfigModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.getRequiredFields());
      }
    });
  });
  test('ServiceModel (core/database/models/service_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f20.ServiceModel.fromMap(sampleServiceModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            name: 'id-1',
            description: 'id-1',
            category: 'id-1',
            isActive: true,
            requiresCertification: true,
            pricingModel: 'id-1',
            legalDisclaimer: 'id-1',
            createdAt: DateTime.utc(2026, 1, 2, 15),
            updatedAt: DateTime.utc(2026, 1, 2, 15)));
      }
    });
  });
  test('SubscriptionModel (core/database/models/subscription_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f21.SubscriptionModel.fromMap(sampleSubscriptionModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            userId: 'id-1',
            planType: 'id-1',
            status: 'id-1',
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15),
            createdAt: DateTime.utc(2026, 1, 2, 15),
            updatedAt: DateTime.utc(2026, 1, 2, 15)));
      }
    });
  });
  test('UserBlockModel (core/database/models/user_block_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f22.UserBlockModel.fromMap(sampleUserBlockModel));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('UserConsentModel (core/database/models/user_consent_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f23.UserConsentModel.fromMap(sampleUserConsentModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            userId: 'id-1',
            consentVersion: 'id-1',
            accepted: true,
            acceptedAt: DateTime.utc(2026, 1, 2, 15),
            ipAddress: 'id-1',
            userAgent: 'id-1'));
      }
    });
  });
  test('UserModel (core/database/models/user_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f24.UserModel.fromMap(sampleUserModel));
      if (o != null) {
        await call(() => o.isActive);
        await call(() => o.isSuspended);
        await call(() => o.isBlocked);
        await call(() => o.userRole);
        await call(() => o.toMap());
        await call(() => o.copyWith(
            id: 'id-1',
            name: 'id-1',
            email: 'id-1',
            password: 'valor-de-prueba',
            role: 'id-1',
            accountStatus: 'id-1',
            profilePhotoPath: 'id-1',
            clearProfilePhoto: true,
            createdAt: DateTime.utc(2026, 1, 2, 15)));
      }
    });
  });
  test('WorkerModel (core/database/models/worker_model.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f25.WorkerModel.fromMap(sampleWorkerModel));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            userId: 'id-1',
            profession: 'id-1',
            description: 'id-1',
            rating: 1.0,
            isAvailable: true,
            visitFee: 1.0,
            serviceCategory: 'id-1',
            pricingTiers: const {},
            customServices: [
              f26.WorkerCustomService.fromMap(sampleWorkerCustomService)
            ],
            pricingConfigured: true,
            workZone: 'id-1',
            baseLatitude: 1.0,
            baseLongitude: 1.0,
            catalogBaseIsApproximate: true,
            serviceRadiusKm: 1.0,
            baseOrigin: 'id-1',
            rejectionCount: 1,
            listingScore: 1.0,
            manualPriority: 1,
            completedJobs: 1,
            isElite: true,
            urbanRadiusKm: 1.0,
            outsideMobilizationFeeClp: 1,
            availableHours: [f27.WorkerHourSlot(weekday: 1, time: 'id-1')]));
      }
    });
  });
  test('WorkerReviewModel (core/database/models/worker_review_model.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f28.WorkerReviewModel(
          id: 'id-1', score: 1, createdAt: DateTime.utc(2026, 1, 2, 15)));
      if (o != null) {
        await call(() => o.displayReviewerName);
        await call(() => o.hasComment);
      }
    });
  });
  test('AbuseRepository (core/database/repositories/abuse_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f29.AbuseRepository());
      if (o != null) {
        await call(() => o.createAbuseEvent(
            f0.AbuseEventModel.fromMap(sampleAbuseEventModel)));
        await call(() => o.getAbuseEventsByUserId('id-1'));
        await call(() => o.getUnresolvedAbuseEvents());
        await call(() => o.updateAbuseEvent(
            f0.AbuseEventModel.fromMap(sampleAbuseEventModel)));
        await call(() => o.resolveAbuseEvent('id-1'));
      }
    });
  });
  test(
      'AdminCatalogRepository (core/database/repositories/admin/admin_catalog_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f30.AdminCatalogRepository());
      if (o != null) {
        await call(
            () => o.listWorkers(limit: 1, search: 'id-1', availableOnly: true));
        await call(() => o.setWorkerAvailability('id-1', true));
        await call(() => o.listFeatureFlags());
        await call(() => o.upsertFeatureFlag(
            f6.FeatureFlagModel.fromMap(sampleFeatureFlagModel)));
        await call(() => o.deleteFeatureFlag('id-1'));
        await call(() => o.listAllServices());
        await call(() => o.setServiceActive('id-1', true));
      }
    });
  });
  test(
      'AdminIncidentsRepository (core/database/repositories/admin/admin_incidents_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f31.AdminIncidentsRepository());
      if (o != null) {
        await call(
            () => o.listDisputes(status: 'id-1', search: 'id-1', limit: 1));
        await call(() => o.markDisputeUnderReview('id-1'));
        await call(
            () => o.listReports(status: 'id-1', search: 'id-1', limit: 1));
        await call(() => o.updateReportStatus('id-1', 'id-1'));
        await call(() => o.listErrorLogs(status: 'id-1', search: 'id-1'));
        await call(() => o.updateErrorLogStatus('id-1', 'id-1'));
        await call(() =>
            o.listPendingActions(status: 'id-1', search: 'id-1', limit: 1));
        await call(() =>
            o.listAbuseEvents(unresolvedOnly: true, search: 'id-1', limit: 1));
        await call(() => o.resolveAbuseEvent('id-1'));
      }
    });
  });
  test(
      'AdminJobsRepository (core/database/repositories/admin/admin_jobs_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f32.AdminJobsRepository());
      if (o != null) {
        await call(() => o.listJobs(status: 'id-1', search: 'id-1', limit: 1));
        await call(() => o.updateJobStatus('id-1', 'id-1'));
        await call(() => o.getJobDetail('id-1'));
      }
    });
  });
  test(
      'AdminMetricsRepository (core/database/repositories/admin/admin_metrics_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f33.AdminMetricsRepository());
      if (o != null) {
        await call(() => o.getMetrics());
      }
    });
  });
  test('AdminMetrics (core/database/repositories/admin/admin_models.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f34.AdminMetrics(
          usersCount: 1,
          workersCount: 1,
          jobsCount: 1,
          openDisputesCount: 1,
          pendingReportsCount: 1,
          underReviewDisputesCount: 1,
          activeJobsCount: 1,
          newErrorsCount: 1,
          unresolvedAbuseCount: 1,
          failedSyncCount: 1));
      if (o != null) {
        await call(() => o.totalIncidents);
      }
    });
  });
  test(
      'AdminUsersRepository (core/database/repositories/admin/admin_users_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f35.AdminUsersRepository());
      if (o != null) {
        await call(() => o.listUsers(
            limit: 1, role: 'id-1', search: 'id-1', accountStatus: 'id-1'));
        await call(() => o.updateAccountStatus('id-1', 'id-1'));
      }
    });
  });
  test('AdminRepository (core/database/repositories/admin_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f36.AdminRepository());
      if (o != null) {
        await call(() => o.getMetrics());
        await call(() => o.listUsers(
            limit: 1, role: 'id-1', search: 'id-1', accountStatus: 'id-1'));
        await call(() => o.updateAccountStatus('id-1', 'id-1'));
        await call(
            () => o.listDisputes(status: 'id-1', search: 'id-1', limit: 1));
        await call(() => o.markDisputeUnderReview('id-1'));
        await call(
            () => o.listReports(status: 'id-1', search: 'id-1', limit: 1));
        await call(() => o.updateReportStatus('id-1', 'id-1'));
        await call(() => o.listJobs(status: 'id-1', search: 'id-1', limit: 1));
        await call(() => o.updateJobStatus('id-1', 'id-1'));
        await call(() => o.getJobDetail('id-1'));
        await call(
            () => o.listWorkers(limit: 1, search: 'id-1', availableOnly: true));
        await call(() => o.setWorkerAvailability('id-1', true));
        await call(() => o.listErrorLogs(status: 'id-1', search: 'id-1'));
        await call(() => o.updateErrorLogStatus('id-1', 'id-1'));
        await call(() =>
            o.listPendingActions(status: 'id-1', search: 'id-1', limit: 1));
        await call(() =>
            o.listAbuseEvents(unresolvedOnly: true, search: 'id-1', limit: 1));
        await call(() => o.resolveAbuseEvent('id-1'));
        await call(() => o.listFeatureFlags());
        await call(() => o.upsertFeatureFlag(
            f6.FeatureFlagModel.fromMap(sampleFeatureFlagModel)));
        await call(() => o.deleteFeatureFlag('id-1'));
        await call(() => o.listAllServices());
        await call(() => o.setServiceActive('id-1', true));
        await call(() => o.fetchRankingConfig());
        await call(() => o
            .saveRankingConfig(f16.RankingConfig.fromMap(sampleRankingConfig)));
        await call(() => o.setWorkerPriority('id-1', 1));
        await call(() => o.listReviewSignals(status: 'id-1', limit: 1));
        await call(() => o.resolveReviewSignal('id-1', 'id-1'));
        await call(() => o.learnRankingWeights());
        await call(() => o.refreshRanking());
      }
    });
  });
  test(
      'AnalyticsRepository (core/database/repositories/analytics_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f37.AnalyticsRepository());
      if (o != null) {
        await call(() => o.trackEvent(
            f1.AnalyticsEventModel.fromMap(sampleAnalyticsEventModel)));
        await call(() => o.trackEvents(
            [f1.AnalyticsEventModel.fromMap(sampleAnalyticsEventModel)]));
        await call(() => o.getEvents(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15),
            eventName: 'id-1',
            userId: 'id-1'));
        await call(() => o.cleanOldEvents(1));
        await call(() => o.getEventCounts(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15)));
        await call(() => o.syncPendingEvents());
      }
    });
  });
  test(
      'AppErrorLogRepository (core/database/repositories/app_error_log_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f38.AppErrorLogRepository());
      if (o != null) {
        await call(() => o.logError(
            message: 'id-1',
            userId: 'id-1',
            errorType: 'id-1',
            stackTrace: 'id-1',
            metadata: const {},
            appVersion: 'id-1',
            platform: 'id-1'));
        await call(() => o.listLogs(status: 'id-1', limit: 1));
        await call(() => o.updateStatus('id-1', 'id-1'));
      }
    });
  });
  test('BoostRepository (core/database/repositories/boost_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f39.BoostRepository());
      if (o != null) {
        await call(
            () => o.createBoost(f3.BoostModel.fromMap(sampleBoostModel)));
        await call(() => o.getActiveBoosts('id-1'));
        await call(() => o.getAllBoosts());
        await call(() => o.deleteBoost('id-1'));
      }
    });
  });
  test(
      'ChangeOrderRepository (core/database/repositories/change_order_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f40.ChangeOrderRepository());
      if (o != null) {
        await call(() =>
            o.create(f4.ChangeOrderModel.fromMap(sampleChangeOrderModel)));
        await call(() => o.getByJobId('id-1'));
        await call(() => o.countPendingClient('id-1'));
        await call(() => o.countApprovedUnpaid('id-1'));
        await call(() =>
            o.update(f4.ChangeOrderModel.fromMap(sampleChangeOrderModel)));
      }
    });
  });
  test(
      'ClientRatingRepository (core/database/repositories/client_rating_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f41.ClientRatingRepository());
      if (o != null) {
        await call(() => o.fetchReputation('id-1'));
        await call(
            () => o.rateClient(jobId: 'id-1', score: 1, comment: 'id-1'));
      }
    });
  });
  test('DisputeRepository (core/database/repositories/dispute_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f42.DisputeRepository());
      if (o != null) {
        await call(
            () => o.createDispute(f5.DisputeModel.fromMap(sampleDisputeModel)));
        await call(() => o.appeal('id-1', 'id-1'));
        await call(() => o.addComment('id-1', 'id-1'));
        await call(() => o.getDisputeById('id-1'));
        await call(() => o.getDisputeByJobId('id-1'));
        await call(
            () => o.updateDispute(f5.DisputeModel.fromMap(sampleDisputeModel)));
        await call(() => o.pendingAgreement('id-1'));
        await call(
            () => o.proposeAgreement(id: 'id-1', jobId: 'id-1', type: 'id-1'));
        await call(() => o.respondAgreement(id: 'id-1', accept: true));
        await call(() => o.listForParticipant('id-1'));
        await call(() => o.getOpenDisputes());
      }
    });
  });
  test(
      'FeatureFlagRepository (core/database/repositories/feature_flag_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f43.FeatureFlagRepository());
      if (o != null) {
        await call(() =>
            o.upsertFlag(f6.FeatureFlagModel.fromMap(sampleFeatureFlagModel)));
        await call(() => o.getFlag(
            flagName: 'id-1',
            appVersion: 'id-1',
            role: 'id-1',
            userId: 'id-1'));
        await call(() => o.getAllFlags());
        await call(() => o.deleteFlag('id-1'));
      }
    });
  });
  test(
      'JobCancellationRepository (core/database/repositories/job_cancellation_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f44.JobCancellationRepository());
      if (o != null) {
        await call(() => o.createCancellation(
            f7.JobCancellationModel.fromMap(sampleJobCancellationModel)));
        await call(() => o.getCancellationByJobId('id-1'));
      }
    });
  });
  test(
      'JobPhotoRepository (core/database/repositories/job_photo_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f45.JobPhotoRepository());
      if (o != null) {
        await call(() =>
            o.createJobPhoto(f9.JobPhotoModel.fromMap(sampleJobPhotoModel)));
        await call(() => o.getPhotosByJobId('id-1'));
        await call(() => o.deleteJobPhoto('id-1'));
        await call(() => o.deletePhotosByJobId('id-1'));
        await call(() => o.getPhotoCountByJobId('id-1'));
        await call(() => o.getEvidenceCountByJobId('id-1'));
      }
    });
  });
  test('JobRepository (core/database/repositories/job_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f46.JobRepository());
      await call(() => f46.JobRepository.parseBusyWorkerIds(null));
      if (o != null) {
        await call(() => o.createJob(f8.JobModel.fromMap(sampleJobModel)));
        await call(() => o.getJobById('id-1'));
        await call(() => o.getJobsByUserId('id-1'));
        await call(() => o.getInProgressJobsByUserId('id-1'));
        await call(() => o.getJobsByWorkerId('id-1'));
        await call(() => o.getHistoryLiveJobs(userId: 'id-1', asWorker: true));
        await call(() => o.getHistoryPastPage(
            userId: 'id-1', asWorker: true, offset: 1, limit: 1));
        await call(() => o.getPendingJobsForWorker('id-1'));
        await call(() => o.getIncomingJobsForWorker('id-1'));
        await call(() => o.getActiveJobsByWorkerId('id-1'));
        await call(() => o.hasActiveJobs('id-1'));
        await call(() => o.getBusyWorkerIds(['id-1']));
        await call(() => o.countJobsByUserId('id-1'));
        await call(() => o.countJobsByWorkerId('id-1'));
        await call(() => o.getJobsByStatus('id-1'));
        await call(() =>
            o.updateJob(f8.JobModel.fromMap(sampleJobModel), pin: 'id-1'));
        await call(() => o.rejectPendingJobByWorker(
            jobId: 'id-1', workerId: 'id-1', metadata: const {}));
        await call(() => o.updateJobStatus('id-1', 'id-1', pin: 'id-1'));
        await call(() => o.confirmStartPin('id-1', 'id-1'));
        await call(() => o.fetchClientStartPin('id-1'));
        await call(() => o.assignWorker('id-1', 'id-1'));
        await call(() => o.deleteJob('id-1'));
        await call(() => o.requestWorker(jobId: 'id-1', workerId: 'id-1'));
        await call(() => o.closeOnClientApproval('id-1'));
        await call(() => o.linkQuotedWorker(jobId: 'id-1', workerId: 'id-1'));
        await call(() => o.syncPaymentStatusFromLedger('id-1'));
        await call(() => o.listOpenMarketplaceJobs());
        await call(() => o.getWorkerJobStats(['id-1']));
        await call(() => o.getWorkerJobs('id-1'));
      }
    });
  });
  test('MessageRepository (core/database/repositories/message_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f47.MessageRepository());
      if (o != null) {
        await call(() =>
            o.createMessage(f10.MessageModel.fromMap(sampleMessageModel)));
        await call(() => o.getMessagesByJobId('id-1'));
        await call(() => o.getUnreadMessages('id-1'));
        await call(() => o.markAsRead('id-1'));
        await call(() => o.markAllAsRead('id-1', 'id-1'));
        await call(() => o.getUnreadCount('id-1'));
        await call(() => o.getMessagesByUserId('id-1'));
      }
    });
  });
  test(
      'NotificationRepository (core/database/repositories/notification_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f48.NotificationRepository());
      if (o != null) {
        await call(() => o.createNotification(
            f11.NotificationModel.fromMap(sampleNotificationModel)));
        await call(() => o.createNotifications(
            [f11.NotificationModel.fromMap(sampleNotificationModel)]));
        await call(() => o.getNotificationsByUserId('id-1'));
        await call(() => o.hasUnread('id-1'));
        await call(() => o.getUnreadNotifications('id-1'));
        await call(() => o.markAsRead('id-1'));
        await call(() => o.markAllAsRead('id-1'));
        await call(() => o.getUnreadCount('id-1'));
        await call(() => o.deleteNotification('id-1'));
      }
    });
  });
  test('PaymentRepository (core/database/repositories/payment_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f49.PaymentRepository());
      if (o != null) {
        await call(() =>
            o.createPayment(f12.PaymentModel.fromMap(samplePaymentModel)));
        await call(() => o.getPaymentById('id-1'));
        await call(() => o.getPaymentByJobId('id-1'));
        await call(() => o.getPrimaryByJobId('id-1'));
        await call(() => o.transitionPaymentStatus(
            paymentId: 'id-1',
            newStatus: 'id-1',
            transferRef: 'id-1',
            notes: 'id-1'));
        await call(() => o.listByJobIds(['id-1']));
      }
    });
  });
  test('PayoutRepository (core/database/repositories/payout_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f50.PayoutRepository());
      if (o != null) {
        await call(() => o.loadAccount('id-1'));
        await call(() => o.saveAccount(
            userId: 'id-1',
            account: f50.BankAccount.fromMap(sampleBankAccount)));
        await call(() => o.summaryForWorker('id-1'));
        await call(() => o.pendingForAdmin());
        await call(() =>
            o.markPaid(paymentId: 'id-1', reference: 'id-1', notes: 'id-1'));
      }
    });
  });
  test(
      'PendingActionRepository (core/database/repositories/pending_action_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f51.PendingActionRepository());
      if (o != null) {
        await call(() => o.createPendingAction(
            userId: 'id-1',
            actionType: 'id-1',
            entityType: 'id-1',
            entityId: 'id-1',
            data: const {}));
        await call(() => o.getPendingActions('id-1'));
        await call(() => o.updateActionStatus(
            actionId: 'id-1', status: 'id-1', errorMessage: 'id-1'));
        await call(() => o.incrementRetryCount('id-1'));
        await call(() => o.setRetryCount('id-1', 1));
        await call(() => o.updateStatus('id-1', 'id-1'));
        await call(() => o.updateErrorMessage('id-1', 'id-1'));
        await call(() => o.getPendingActionById('id-1'));
        await call(() => o.getActionById('id-1'));
        await call(() => o.deleteAction('id-1'));
        await call(() => o.deleteSyncedActions(daysOld: 1));
      }
    });
  });
  test(
      'PortfolioRepository (core/database/repositories/portfolio_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f52.PortfolioRepository());
      if (o != null) {
        await call(() => o.createPortfolioItem(
            f14.PortfolioModel.fromMap(samplePortfolioModel)));
        await call(() => o.getPortfolioByWorkerId('id-1'));
        await call(() => o.deletePortfolioItem('id-1'));
      }
    });
  });
  test(
      'QuoteProposalRepository (core/database/repositories/quote_proposal_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f53.QuoteProposalRepository());
      if (o != null) {
        await call(() =>
            o.create(f15.QuoteProposalModel.fromMap(sampleQuoteProposalModel)));
        await call(() => o.getByJobId('id-1'));
        await call(() => o.getById('id-1'));
        await call(() => o.selectAsClient('id-1'));
        await call(() =>
            o.update(f15.QuoteProposalModel.fromMap(sampleQuoteProposalModel)));
      }
    });
  });
  test('RankingRepository (core/database/repositories/ranking_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f54.RankingRepository());
      if (o != null) {
        await call(() => o.fetchConfig());
        await call(
            () => o.saveConfig(f16.RankingConfig.fromMap(sampleRankingConfig)));
        await call(() => o.setWorkerPriority('id-1', 1));
        await call(() => o.listSignals(status: 'id-1', limit: 1));
        await call(() => o.resolveSignal('id-1', 'id-1'));
        await call(() => o.learnWeights());
        await call(() => o.refreshAll());
        await call(() => o.pendingSignalCount());
      }
    });
  });
  test('RatingRepository (core/database/repositories/rating_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f55.RatingRepository());
      if (o != null) {
        await call(
            () => o.createRating(f17.RatingModel.fromMap(sampleRatingModel)));
        await call(() => o.getRatingByJobId('id-1', direction: 'id-1'));
        await call(() => o.clientSummaries(['id-1']));
        await call(() => o.getRatingsByWorkerId('id-1'));
        await call(() => o.getAverageRatingByWorkerId('id-1'));
        await call(() => o.listReceived('id-1'));
        await call(() => o.getRatingsByUserId('id-1'));
        await call(() => o.getWorkerReviewsForProfile('id-1', limit: 1));
      }
    });
  });
  test('ReportRepository (core/database/repositories/report_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f56.ReportRepository());
      if (o != null) {
        await call(
            () => o.createReport(f18.ReportModel.fromMap(sampleReportModel)));
        await call(() => o.getReportsByReporterId('id-1'));
        await call(() => o.getReportsByReportedUserId('id-1'));
        await call(() => o.updateReportStatus('id-1', 'id-1'));
      }
    });
  });
  test(
      'RescheduleRepository (core/database/repositories/reschedule_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f57.RescheduleRepository());
      if (o != null) {
        await call(() => o.history('id-1'));
        await call(() => o.propose(
            jobId: 'id-1', at: DateTime.utc(2026, 1, 2, 15), reason: 'id-1'));
        await call(() => o.respond('id-1', accept: true));
        await call(() => o.withdraw('id-1'));
      }
    });
  });
  test(
      'ServiceConfigRepository (core/database/repositories/service_config_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f58.ServiceConfigRepository());
      if (o != null) {
        await call(() => o.getConfigByServiceId('id-1'));
        await call(() => o.createConfig(
            f19.ServiceConfigModel.fromMap(sampleServiceConfigModel)));
        await call(() => o.updateConfig(
            f19.ServiceConfigModel.fromMap(sampleServiceConfigModel)));
      }
    });
  });
  test('ServiceRepository (core/database/repositories/service_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f59.ServiceRepository());
      await call(() => f59.ServiceRepository.clearCache());
      if (o != null) {
        await call(() => o.getAllServices());
        await call(() => o.getServicesByCategory('id-1'));
        await call(() => o.getServiceById('id-1'));
        await call(() =>
            o.createService(f20.ServiceModel.fromMap(sampleServiceModel)));
        await call(() =>
            o.updateService(f20.ServiceModel.fromMap(sampleServiceModel)));
        await call(() => o.getMainServices());
      }
    });
  });
  test(
      'SubscriptionRepository (core/database/repositories/subscription_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f60.SubscriptionRepository());
      if (o != null) {
        await call(() => o.createSubscription(
            f21.SubscriptionModel.fromMap(sampleSubscriptionModel)));
        await call(() => o.getSubscriptionById('id-1'));
        await call(() => o.getActiveSubscription('id-1'));
        await call(() => o.getActiveSubscriptions());
        await call(() => o.updateSubscription(
            f21.SubscriptionModel.fromMap(sampleSubscriptionModel)));
      }
    });
  });
  test(
      'UserBlockRepository (core/database/repositories/user_block_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f61.UserBlockRepository());
      if (o != null) {
        await call(() =>
            o.createBlock(f22.UserBlockModel.fromMap(sampleUserBlockModel)));
        await call(() => o.isBlocked('id-1', 'id-1'));
        await call(() => o.getBlockedUserIds('id-1'));
        await call(() => o.removeBlock('id-1', 'id-1'));
      }
    });
  });
  test(
      'UserConsentRepository (core/database/repositories/user_consent_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f62.UserConsentRepository());
      if (o != null) {
        await call(() => o.createConsent(
            f23.UserConsentModel.fromMap(sampleUserConsentModel)));
        await call(() => o.getLatestConsent('id-1'));
        await call(() => o.hasAcceptedCurrentVersion('id-1', 'id-1'));
        await call(() => o.getUserConsents('id-1'));
        await call(() => o.deleteUserConsents('id-1'));
      }
    });
  });
  test('UserRepository (core/database/repositories/user_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f63.UserRepository());
      await call(() => f63.UserRepository.invalidateCachedUser('id-1'));
      if (o != null) {
        await call(() => o.createUser(f24.UserModel.fromMap(sampleUserModel)));
        await call(() => o.getUserById('id-1'));
        await call(() => o.getPublicProfilesByIds(['id-1']));
        await call(() => o.getPublicProfile('id-1'));
        await call(() => o.getUserByEmail('id-1'));
        await call(() => o.updateUser(f24.UserModel.fromMap(sampleUserModel)));
        await call(() => o.updateProfilePhotoPath('id-1', 'id-1'));
        await call(() => o.updatePassword('valor-de-prueba', 'valor-de-prueba'));
        await call(() => o.updateAccountStatus('id-1', 'id-1'));
        await call(() => o.deleteUser('id-1'));
        await call(() => o.getAllUsers());
      }
    });
  });
  test(
      'VerificationEventRepository (core/database/repositories/verification_event_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f64.VerificationEventRepository());
      if (o != null) {
        await call(() => o.history('id-1'));
      }
    });
  });
  test('WorkerRepository (core/database/repositories/worker_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f65.WorkerRepository());
      if (o != null) {
        await call(
            () => o.createWorker(f25.WorkerModel.fromMap(sampleWorkerModel)));
        await call(() => o.getWorkerByUserId('id-1'));
        await call(() => o.getPublicStats('id-1'));
        await call(() => o.getWorkerById('id-1'));
        await call(() => o.getWorkersByServiceCategory('id-1',
            near: f66.UserLocationContext(city: 'id-1')));
        await call(() => o.getWorkersByProfession('id-1'));
        await call(() => o.getAllAvailableWorkers());
        await call(() => o.getWorkersForLogin());
        await call(() => o.updateWorker(
            f25.WorkerModel.fromMap(sampleWorkerModel),
            savePrices: true,
            saveExtras: true));
        await call(() => o.updateAvailableHours(
            userId: 'id-1',
            hours: [f27.WorkerHourSlot(weekday: 1, time: 'id-1')]));
        await call(() => o.fetchFreeSlots('id-1'));
        await call(() => o.fetchVerification('id-1'));
        await call(
            () => o.submitVerificationReview(userId: 'id-1', note: 'id-1'));
        await call(() => o.updateBaseLocation(
            userId: 'id-1', latitude: 1.0, longitude: 1.0, radiusKm: 1.0));
        await call(() => o.updateUrbanCoverage(
            userId: 'id-1', urbanRadiusKm: 1.0, outsideFeeClp: 1));
        await call(() => o.updateAvailability('id-1', true));
        await call(() => o.isWorkerAcceptingJobs('id-1'));
        await call(() => o.enforceUnavailableWhileBusy('id-1'));
        await call(() => o.syncAvailabilityWithJobs('id-1', email: 'id-1'));
        await call(() => o.getAvailableWorkersWithoutActiveJobs(
            near: f66.UserLocationContext(city: 'id-1')));
        await call(() => o.hasActiveJobs('id-1'));
      }
    });
  });
  test(
      'WorkerScheduleRepository (core/database/repositories/worker_schedule_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f67.WorkerScheduleRepository());
      if (o != null) {
        await call(() => o.load('id-1'));
        await call(() => o.loadMany(['id-1']));
        await call(() => o.ensureDefault(userId: 'id-1'));
        await call(() => o.save(
            userId: 'id-1', schedule: f68.WeeklySchedule(enabled: true)));
      }
    });
  });
  test(
      'WorkerServiceRepository (core/database/repositories/worker_service_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f69.WorkerServiceRepository());
      if (o != null) {
        await call(() => o.linkWorkerToCategory('id-1', 'id-1'));
        await call(() => o.clearWorkerLinks('id-1'));
        await call(() => o.getCategoriesForWorker('id-1'));
      }
    });
  });
}
