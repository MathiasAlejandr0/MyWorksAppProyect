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
            id: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
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
            id: '00000000-0000-4000-8000-0000000000aa',
            jobId: '00000000-0000-4000-8000-0000000000aa',
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
            id: '00000000-0000-4000-8000-0000000000aa',
            flagName: 'id-1',
            isEnabled: true,
            appVersion: 'id-1',
            role: 'id-1',
            userId: '00000000-0000-4000-8000-0000000000aa',
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
            id: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            status: 'id-1',
            address: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            description: 'id-1',
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            serviceMetadata: <String, dynamic>{'id': 'id-1'},
            pricingMode: 'id-1',
            paymentStatus: 'id-1',
            comunaId: '00000000-0000-4000-8000-0000000000aa',
            pricingSnapshot: <String, dynamic>{'id': 'id-1'},
            serviceSkuId: '00000000-0000-4000-8000-0000000000aa',
            hourlyBlockHours: 1,
            selectedQuoteId: '00000000-0000-4000-8000-0000000000aa',
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
            id: '00000000-0000-4000-8000-0000000000aa',
            jobId: '00000000-0000-4000-8000-0000000000aa',
            changeOrderId: '00000000-0000-4000-8000-0000000000aa',
            paymentType: 'id-1',
            amount: 1.0,
            currency: 'id-1',
            status: 'id-1',
            paymentMethod: 'id-1',
            transactionId: '00000000-0000-4000-8000-0000000000aa',
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
            id: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
            actionType: 'id-1',
            entityType: 'id-1',
            entityId: '00000000-0000-4000-8000-0000000000aa',
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
            pesosSenal: <String, double>{}));
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
            id: '00000000-0000-4000-8000-0000000000aa',
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
            id: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
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
            id: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
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
            id: '00000000-0000-4000-8000-0000000000aa',
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
            userId: '00000000-0000-4000-8000-0000000000aa',
            profession: 'id-1',
            description: 'id-1',
            rating: 1.0,
            isAvailable: true,
            visitFee: 1.0,
            serviceCategory: 'id-1',
            pricingTiers: <String, int>{},
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
        await call(() =>
            o.getAbuseEventsByUserId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getUnresolvedAbuseEvents());
        await call(() => o.updateAbuseEvent(
            f0.AbuseEventModel.fromMap(sampleAbuseEventModel)));
        await call(
            () => o.resolveAbuseEvent('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() => o.setWorkerAvailability(
            '00000000-0000-4000-8000-0000000000aa', true));
        await call(() => o.listFeatureFlags());
        await call(() => o.upsertFeatureFlag(
            f6.FeatureFlagModel.fromMap(sampleFeatureFlagModel)));
        await call(
            () => o.deleteFeatureFlag('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.listAllServices());
        await call(() =>
            o.setServiceActive('00000000-0000-4000-8000-0000000000aa', true));
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
        await call(() =>
            o.markDisputeUnderReview('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.listReports(status: 'id-1', search: 'id-1', limit: 1));
        await call(() => o.updateReportStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() => o.listErrorLogs(status: 'id-1', search: 'id-1'));
        await call(() => o.updateErrorLogStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() =>
            o.listPendingActions(status: 'id-1', search: 'id-1', limit: 1));
        await call(() =>
            o.listAbuseEvents(unresolvedOnly: true, search: 'id-1', limit: 1));
        await call(
            () => o.resolveAbuseEvent('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() =>
            o.updateJobStatus('00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(
            () => o.getJobDetail('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() => o.updateAccountStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
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
        await call(() => o.updateAccountStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(
            () => o.listDisputes(status: 'id-1', search: 'id-1', limit: 1));
        await call(() =>
            o.markDisputeUnderReview('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.listReports(status: 'id-1', search: 'id-1', limit: 1));
        await call(() => o.updateReportStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() => o.listJobs(status: 'id-1', search: 'id-1', limit: 1));
        await call(() =>
            o.updateJobStatus('00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(
            () => o.getJobDetail('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.listWorkers(limit: 1, search: 'id-1', availableOnly: true));
        await call(() => o.setWorkerAvailability(
            '00000000-0000-4000-8000-0000000000aa', true));
        await call(() => o.listErrorLogs(status: 'id-1', search: 'id-1'));
        await call(() => o.updateErrorLogStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() =>
            o.listPendingActions(status: 'id-1', search: 'id-1', limit: 1));
        await call(() =>
            o.listAbuseEvents(unresolvedOnly: true, search: 'id-1', limit: 1));
        await call(
            () => o.resolveAbuseEvent('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.listFeatureFlags());
        await call(() => o.upsertFeatureFlag(
            f6.FeatureFlagModel.fromMap(sampleFeatureFlagModel)));
        await call(
            () => o.deleteFeatureFlag('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.listAllServices());
        await call(() =>
            o.setServiceActive('00000000-0000-4000-8000-0000000000aa', true));
        await call(() => o.fetchRankingConfig());
        await call(() => o
            .saveRankingConfig(f16.RankingConfig.fromMap(sampleRankingConfig)));
        await call(() =>
            o.setWorkerPriority('00000000-0000-4000-8000-0000000000aa', 1));
        await call(() => o.listReviewSignals(status: 'id-1', limit: 1));
        await call(() => o.resolveReviewSignal(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
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
            userId: '00000000-0000-4000-8000-0000000000aa'));
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
            userId: '00000000-0000-4000-8000-0000000000aa',
            errorType: 'id-1',
            stackTrace: 'id-1',
            metadata: <String, dynamic>{'id': 'id-1'},
            appVersion: 'id-1',
            platform: 'id-1'));
        await call(() => o.listLogs(status: 'id-1', limit: 1));
        await call(() =>
            o.updateStatus('00000000-0000-4000-8000-0000000000aa', 'id-1'));
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
        await call(
            () => o.getActiveBoosts('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getAllBoosts());
        await call(() => o.deleteBoost('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() => o.getByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.countPendingClient('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.countApprovedUnpaid('00000000-0000-4000-8000-0000000000aa'));
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
        await call(
            () => o.fetchReputation('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.rateClient(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            score: 1,
            comment: 'id-1'));
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
        await call(
            () => o.appeal('00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(
            () => o.addComment('00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(
            () => o.getDisputeById('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getDisputeByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.updateDispute(f5.DisputeModel.fromMap(sampleDisputeModel)));
        await call(
            () => o.pendingAgreement('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.proposeAgreement(
            id: '00000000-0000-4000-8000-0000000000aa',
            jobId: '00000000-0000-4000-8000-0000000000aa',
            type: 'id-1'));
        await call(() => o.respondAgreement(
            id: '00000000-0000-4000-8000-0000000000aa', accept: true));
        await call(
            () => o.listForParticipant('00000000-0000-4000-8000-0000000000aa'));
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
            userId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getAllFlags());
        await call(() => o.deleteFlag('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() =>
            o.getCancellationByJobId('00000000-0000-4000-8000-0000000000aa'));
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
        await call(
            () => o.getPhotosByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.deleteJobPhoto('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.deletePhotosByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getPhotoCountByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getEvidenceCountByJobId('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() => o.getJobById('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getJobsByUserId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o
            .getInProgressJobsByUserId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getJobsByWorkerId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getHistoryLiveJobs(
            userId: '00000000-0000-4000-8000-0000000000aa', asWorker: true));
        await call(() => o.getHistoryPastPage(
            userId: '00000000-0000-4000-8000-0000000000aa',
            asWorker: true,
            offset: 1,
            limit: 1));
        await call(() =>
            o.getPendingJobsForWorker('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getIncomingJobsForWorker('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getActiveJobsByWorkerId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.hasActiveJobs('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getBusyWorkerIds(<String>['id-1']));
        await call(
            () => o.countJobsByUserId('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.countJobsByWorkerId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getJobsByStatus('id-1'));
        await call(() =>
            o.updateJob(f8.JobModel.fromMap(sampleJobModel), pin: 'id-1'));
        await call(() => o.rejectPendingJobByWorker(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.updateJobStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1',
            pin: 'id-1'));
        await call(() =>
            o.confirmStartPin('00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() =>
            o.fetchClientStartPin('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.assignWorker('00000000-0000-4000-8000-0000000000aa',
            '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.deleteJob('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.requestWorker(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.closeOnClientApproval('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.linkQuotedWorker(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.syncPaymentStatusFromLedger(
            '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.listOpenMarketplaceJobs());
        await call(() => o.getWorkerJobStats(<String>['id-1']));
        await call(
            () => o.getWorkerJobs('00000000-0000-4000-8000-0000000000aa'));
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
        await call(
            () => o.getMessagesByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getUnreadMessages('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.markAsRead('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.markAllAsRead('00000000-0000-4000-8000-0000000000aa',
            '00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getUnreadCount('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getMessagesByUserId('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() =>
            o.getNotificationsByUserId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.hasUnread('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getUnreadNotifications('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.markAsRead('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.markAllAsRead('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getUnreadCount('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.deleteNotification('00000000-0000-4000-8000-0000000000aa'));
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
        await call(
            () => o.getPaymentById('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getPaymentByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getPrimaryByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.transitionPaymentStatus(
            paymentId: '00000000-0000-4000-8000-0000000000aa',
            newStatus: 'id-1',
            transferRef: 'id-1',
            notes: 'id-1'));
        await call(() => o.listByJobIds(<String>['id-1']));
      }
    });
  });
  test('PayoutRepository (core/database/repositories/payout_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f50.PayoutRepository());
      if (o != null) {
        await call(() => o.loadAccount('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.saveAccount(
            userId: '00000000-0000-4000-8000-0000000000aa',
            account: f50.BankAccount.fromMap(sampleBankAccount)));
        await call(
            () => o.summaryForWorker('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.pendingForAdmin());
        await call(() => o.markPaid(
            paymentId: '00000000-0000-4000-8000-0000000000aa',
            reference: 'id-1',
            notes: 'id-1'));
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
            userId: '00000000-0000-4000-8000-0000000000aa',
            actionType: 'id-1',
            entityType: 'id-1',
            entityId: '00000000-0000-4000-8000-0000000000aa',
            data: <String, dynamic>{'id': 'id-1'}));
        await call(
            () => o.getPendingActions('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.updateActionStatus(
            actionId: '00000000-0000-4000-8000-0000000000aa',
            status: 'id-1',
            errorMessage: 'id-1'));
        await call(() =>
            o.incrementRetryCount('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.setRetryCount('00000000-0000-4000-8000-0000000000aa', 1));
        await call(() =>
            o.updateStatus('00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() => o.updateErrorMessage(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() =>
            o.getPendingActionById('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getActionById('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.deleteAction('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() =>
            o.getPortfolioByWorkerId('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.deletePortfolioItem('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() => o.getByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getById('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.selectAsClient('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() =>
            o.setWorkerPriority('00000000-0000-4000-8000-0000000000aa', 1));
        await call(() => o.listSignals(status: 'id-1', limit: 1));
        await call(() =>
            o.resolveSignal('00000000-0000-4000-8000-0000000000aa', 'id-1'));
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
        await call(() => o.getRatingByJobId(
            '00000000-0000-4000-8000-0000000000aa',
            direction: 'id-1'));
        await call(() => o.clientSummaries(<String>['id-1']));
        await call(() =>
            o.getRatingsByWorkerId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getAverageRatingByWorkerId(
            '00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.listReceived('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getRatingsByUserId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getWorkerReviewsForProfile(
            '00000000-0000-4000-8000-0000000000aa',
            limit: 1));
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
        await call(() =>
            o.getReportsByReporterId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getReportsByReportedUserId(
            '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.updateReportStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
      }
    });
  });
  test(
      'RescheduleRepository (core/database/repositories/reschedule_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f57.RescheduleRepository());
      if (o != null) {
        await call(() => o.history('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.propose(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            at: DateTime.utc(2026, 1, 2, 15),
            reason: 'id-1'));
        await call(() =>
            o.respond('00000000-0000-4000-8000-0000000000aa', accept: true));
        await call(() => o.withdraw('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test(
      'ServiceConfigRepository (core/database/repositories/service_config_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f58.ServiceConfigRepository());
      if (o != null) {
        await call(() =>
            o.getConfigByServiceId('00000000-0000-4000-8000-0000000000aa'));
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
        await call(
            () => o.getServiceById('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() =>
            o.getSubscriptionById('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getActiveSubscription('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() => o.isBlocked('00000000-0000-4000-8000-0000000000aa',
            '00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getBlockedUserIds('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.removeBlock('00000000-0000-4000-8000-0000000000aa',
            '00000000-0000-4000-8000-0000000000aa'));
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
        await call(
            () => o.getLatestConsent('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.hasAcceptedCurrentVersion(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(
            () => o.getUserConsents('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.deleteUserConsents('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('UserRepository (core/database/repositories/user_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f63.UserRepository());
      await call(() => f63.UserRepository.invalidateCachedUser(
          '00000000-0000-4000-8000-0000000000aa'));
      if (o != null) {
        await call(() => o.createUser(f24.UserModel.fromMap(sampleUserModel)));
        await call(() => o.getUserById('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getPublicProfilesByIds(<String>['id-1']));
        await call(
            () => o.getPublicProfile('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getUserByEmail('id-1'));
        await call(() => o.updateUser(f24.UserModel.fromMap(sampleUserModel)));
        await call(() => o.updateProfilePhotoPath(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() =>
            o.updatePassword('00000000-0000-4000-8000-0000000000aa', 'valor-de-prueba'));
        await call(() => o.updateAccountStatus(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() => o.deleteUser('00000000-0000-4000-8000-0000000000aa'));
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
        await call(() => o.history('00000000-0000-4000-8000-0000000000aa'));
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
        await call(
            () => o.getWorkerByUserId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getPublicStats('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getWorkerById('00000000-0000-4000-8000-0000000000aa'));
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
            userId: '00000000-0000-4000-8000-0000000000aa',
            hours: [f27.WorkerHourSlot(weekday: 1, time: 'id-1')]));
        await call(
            () => o.fetchFreeSlots('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.fetchVerification('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.submitVerificationReview(
            userId: '00000000-0000-4000-8000-0000000000aa', note: 'id-1'));
        await call(() => o.updateBaseLocation(
            userId: '00000000-0000-4000-8000-0000000000aa',
            latitude: 1.0,
            longitude: 1.0,
            radiusKm: 1.0));
        await call(() => o.updateUrbanCoverage(
            userId: '00000000-0000-4000-8000-0000000000aa',
            urbanRadiusKm: 1.0,
            outsideFeeClp: 1));
        await call(() =>
            o.updateAvailability('00000000-0000-4000-8000-0000000000aa', true));
        await call(() =>
            o.isWorkerAcceptingJobs('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.enforceUnavailableWhileBusy(
            '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.syncAvailabilityWithJobs(
            '00000000-0000-4000-8000-0000000000aa',
            email: 'id-1'));
        await call(() => o.getAvailableWorkersWithoutActiveJobs(
            near: f66.UserLocationContext(city: 'id-1')));
        await call(
            () => o.hasActiveJobs('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test(
      'WorkerScheduleRepository (core/database/repositories/worker_schedule_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f67.WorkerScheduleRepository());
      if (o != null) {
        await call(() => o.load('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.loadMany(<String>['id-1']));
        await call(() =>
            o.ensureDefault(userId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.save(
            userId: '00000000-0000-4000-8000-0000000000aa',
            schedule: f68.WeeklySchedule(enabled: true)));
      }
    });
  });
  test(
      'WorkerServiceRepository (core/database/repositories/worker_service_repository.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f69.WorkerServiceRepository());
      if (o != null) {
        await call(() => o.linkWorkerToCategory(
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(
            () => o.clearWorkerLinks('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getCategoriesForWorker('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
}
