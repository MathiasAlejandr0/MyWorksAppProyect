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
import 'package:myworksapp/core/services/abuse_protection_service.dart' as f0;
import 'package:myworksapp/core/services/account_deletion_service.dart' as f1;
import 'package:myworksapp/core/services/action_timeout_service.dart' as f2;
import 'package:myworksapp/core/services/admin_notification_service.dart' as f3;
import 'package:myworksapp/core/services/ai_service_recommendation_engine.dart'
    as f4;
import 'package:myworksapp/core/database/models/worker_model.dart' as f5;
import 'package:myworksapp/core/services/analytics_service.dart' as f6;
import 'package:myworksapp/core/services/app_feedback.dart' as f7;
import 'package:myworksapp/core/services/app_health_service.dart' as f8;
import 'package:myworksapp/core/services/app_lifecycle_service.dart' as f9;
import 'package:myworksapp/core/services/auth_service.dart' as f10;
import 'package:myworksapp/core/domain/user_role.dart' as f11;
import 'package:myworksapp/core/database/repositories/user_repository.dart'
    as f12;
import 'package:myworksapp/core/services/background_timeout_reconciler.dart'
    as f13;
import 'package:myworksapp/core/services/boost_service.dart' as f14;
import 'package:myworksapp/core/services/change_order_service.dart' as f15;
import 'package:myworksapp/core/database/models/change_order_model.dart' as f16;
import 'package:myworksapp/core/services/crash_reporting_service.dart' as f17;
import 'package:myworksapp/core/utils/app_error.dart' as f18;
import 'package:myworksapp/core/services/demo_tour_service.dart' as f19;
import 'package:myworksapp/core/services/dispute_service.dart' as f20;
import 'package:myworksapp/core/services/evidence_storage_path.dart' as f21;
import 'package:myworksapp/core/services/evidence_uploader.dart' as f22;
import 'package:myworksapp/core/services/evidence_video_limits.dart' as f23;
import 'package:myworksapp/core/services/feature_flags_service.dart' as f24;
import 'package:myworksapp/core/services/gdpr_service.dart' as f25;
import 'package:myworksapp/core/services/geocode_chile.dart' as f26;
import 'package:myworksapp/core/services/gps_publish_gate.dart' as f27;
import 'package:myworksapp/core/services/job_booking_service.dart' as f28;
import 'package:myworksapp/core/services/job_cancellation_service.dart' as f29;
import 'package:myworksapp/core/services/job_service.dart' as f30;
import 'package:myworksapp/core/services/job_state_machine.dart' as f31;
import 'package:myworksapp/core/database/models/job_model.dart' as f32;
import 'package:myworksapp/core/services/job_transition_matrix.dart' as f33;
import 'package:myworksapp/core/services/logout_service.dart' as f34;
import 'package:myworksapp/core/services/matching_service.dart' as f35;
import 'package:myworksapp/core/database/models/user_model.dart' as f36;
import 'package:myworksapp/core/services/notification_opt_in.dart' as f37;
import 'package:myworksapp/core/services/notification_permission_gateway.dart'
    as f38;
import 'package:myworksapp/core/services/notification_realtime_service.dart'
    as f39;
import 'package:myworksapp/core/services/notification_service.dart' as f40;
import 'package:myworksapp/core/database/models/notification_model.dart' as f41;
import 'package:myworksapp/core/services/oauth_deep_link_service.dart' as f42;
import 'package:myworksapp/core/services/open_quote_notification_service.dart'
    as f43;
import 'package:myworksapp/core/database/repositories/job_repository.dart'
    as f44;
import 'package:myworksapp/core/services/payment_gateway_port.dart' as f45;
import 'package:myworksapp/core/services/payment_guard.dart' as f46;
import 'package:myworksapp/core/services/payment_guard_ports.dart' as f47;
import 'package:myworksapp/core/services/payment_service.dart' as f48;
import 'package:myworksapp/core/domain/price_quote.dart' as f49;
import 'package:myworksapp/core/services/permission_denied_handler.dart' as f50;
import 'package:myworksapp/core/services/photo_service.dart' as f51;
import 'package:myworksapp/core/services/pricing_guard_service.dart' as f52;
import 'package:myworksapp/core/services/pricing_mode_questionnaire_service.dart'
    as f53;
import 'package:myworksapp/core/services/pricing_service.dart' as f54;
import 'package:myworksapp/core/domain/worker_service_options_catalog.dart'
    as f55;
import 'package:myworksapp/core/domain/job_charge_preview.dart' as f56;
import 'package:myworksapp/core/services/profile_photo_service.dart' as f57;
import 'package:myworksapp/core/services/push_notification_port.dart' as f58;
import 'package:myworksapp/core/services/push_service.dart' as f59;
import 'package:myworksapp/core/services/quote_proposal_service.dart' as f60;
import 'package:myworksapp/core/services/rate_limiter_service.dart' as f61;
import 'package:myworksapp/core/services/report_service.dart' as f62;
import 'package:myworksapp/core/services/service_legal_validator.dart' as f63;
import 'package:myworksapp/core/services/session_manager.dart' as f64;
import 'package:myworksapp/core/services/subscription_service.dart' as f65;
import 'package:myworksapp/core/services/testing_feedback_store.dart' as f66;
import 'package:myworksapp/core/services/transbank_webpay_gateway.dart' as f67;
import 'package:myworksapp/core/services/trust_score_service.dart' as f68;
import 'package:myworksapp/core/services/user_location_service.dart' as f69;
import 'package:myworksapp/core/domain/user_location_context.dart' as f70;
import 'package:myworksapp/core/services/worker_earnings_service.dart' as f71;
import 'package:myworksapp/core/services/worker_job_rejection_service.dart'
    as f72;
import 'package:myworksapp/core/services/worker_onboarding_checklist_service.dart'
    as f73;
import 'package:myworksapp/core/services/worker_reputation_service.dart' as f74;
import 'package:myworksapp/core/services/worker_search_service.dart' as f75;
import 'support/model_samples.dart';
import 'support/scenarios.dart';

void main() {
  setUpAll(setUpScenarios);
  test('AbuseProtectionService (core/services/abuse_protection_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f0.AbuseProtectionService.instance);
      if (o != null) {
        await call(
            () => o.canCreateJob('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.canRejectJob('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.canCancelJob('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.isShadowBanned('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.resolveAbuseEvent('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getAbuseEventsByUserId('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('AccountDeletionService (core/services/account_deletion_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f1.AccountDeletionService.instance);
      if (o != null) {
        await call(
            () => o.deleteAccount('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.isAccountDeleted('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getAnonymizedName('id-1'));
        await call(() => o.getAnonymizedEmail('id-1'));
      }
    });
  });
  test(
      'AdminNotificationService (core/services/admin_notification_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f3.AdminNotificationService.instance);
      if (o != null) {
        await call(() => o.notifyReportStatusChange(
            reporterId: '00000000-0000-4000-8000-0000000000aa',
            reportedUserId: '00000000-0000-4000-8000-0000000000aa',
            status: 'id-1',
            reportId: '00000000-0000-4000-8000-0000000000aa',
            reason: 'id-1'));
        await call(() => o.notifyDisputeUnderReview(
            userId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            jobId: '00000000-0000-4000-8000-0000000000aa',
            disputeId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.notifyDisputeResolved(
            userId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            disputeId: '00000000-0000-4000-8000-0000000000aa',
            resolution: 'id-1'));
      }
    });
  });
  test(
      'AiServiceRecommendationEngine (core/services/ai_service_recommendation_engine.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f4.AiServiceRecommendationEngine.instance);
      if (o != null) {
        await call(() => o.analyzeQuery('id-1'));
      }
    });
  });
  test('AnalyticsService (core/services/analytics_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f6.AnalyticsService.instance);
      if (o != null) {
        await call(() => o.setEnabled(true));
        await call(() => o.registrarUso(
            eventName: 'id-1',
            userId: '00000000-0000-4000-8000-0000000000aa',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.trackEvent(
            eventName: 'id-1',
            userId: '00000000-0000-4000-8000-0000000000aa',
            role: 'id-1',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.trackAppOpened(
            userId: '00000000-0000-4000-8000-0000000000aa', role: 'id-1'));
        await call(() => o.trackRegisterCompleted(
            userId: '00000000-0000-4000-8000-0000000000aa',
            role: 'id-1',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.trackLoginSuccess(
            userId: '00000000-0000-4000-8000-0000000000aa', role: 'id-1'));
        await call(() => o.trackJobCreated(
            userId: '00000000-0000-4000-8000-0000000000aa',
            jobId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.trackJobAccepted(
            workerId: '00000000-0000-4000-8000-0000000000aa',
            jobId: '00000000-0000-4000-8000-0000000000aa',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.trackJobExpired(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.trackJobCancelled(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
            role: 'id-1',
            reason: 'id-1',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.trackJobCompleted(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.trackWorkerNoResponse(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.trackDisputeOpened(
            disputeId: '00000000-0000-4000-8000-0000000000aa',
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
            reason: 'id-1'));
        await call(() => o.trackRatingSubmitted(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            score: 1,
            hasComment: true));
        await call(() => o.getEventStats(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15)));
        await call(() => o.cleanOldEvents(daysToKeep: 1));
        await call(() => o.syncPendingEvents());
        await call(() => o.trackEventWithCategory(
            eventName: 'id-1',
            category: 'id-1',
            userId: '00000000-0000-4000-8000-0000000000aa',
            role: 'id-1',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.calculateUserToRequestConversion(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15)));
        await call(() => o.calculateWorkerAcceptanceRate(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15)));
        await call(() => o.calculateAverageResponseTime(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15)));
        await call(() => o.calculateCancellationRateByService(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15)));
        await call(() => o.calculateUserRepeatRate(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15)));
        await call(() => o.getBusinessMetrics(
            startDate: DateTime.utc(2026, 1, 2, 15),
            endDate: DateTime.utc(2026, 1, 2, 15)));
      }
    });
  });
  test('BusinessMetrics (core/services/analytics_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f6.BusinessMetrics(
          userToRequestConversion: 1.0,
          workerAcceptanceRate: 1.0,
          averageResponseTimeMinutes: 1.0,
          cancellationRateByService: <String, double>{},
          userRepeatRate: 1.0));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('AppFeedback (core/services/app_feedback.dart)', () async {
    await forEachScenario(() async {
      await call(() => f7.AppFeedback.light());
      await call(() => f7.AppFeedback.medium());
      await call(() => f7.AppFeedback.heavy());
      await call(() => f7.AppFeedback.selection());
    });
  });
  test('AppHealthService (core/services/app_health_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f8.AppHealthService.instance);
      if (o != null) {
        await call(() => o.status);
        await call(() => o.lastFailureType);
        await call(() => o.lastFailureMessage);
        await call(() => o.isMaintenanceMode);
        await call(() => o.checkHealth());
        await call(() => o.activateMaintenanceMode(reason: 'id-1'));
        await call(() => o.deactivateMaintenanceMode());
        await call(() => o.attemptRecovery(restoreBackup: true));
        await call(() => o.getDiagnostics());
      }
    });
  });
  test('SupabaseAuthService (core/services/auth_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(
          () => f10.SupabaseAuthService(userRepository: f12.UserRepository()));
      if (o != null) {
        await call(() => o.currentUserId);
        await call(() => o.sessionChanges);
        await call(() => o.register(
            name: 'id-1',
            email: 'id-1',
            password: 'valor-de-prueba',
            role: f11.UserRole.values.first));
        await call(() => o.login(email: 'valor-de-prueba', password: 'valor-de-prueba'));
        await call(() => o.loginWithOAuth(f10.SocialAuthProvider.values.first));
        await call(() => o.completeOAuthSession());
        await call(() => o.logout());
        await call(() => o.restoreSession());
        await call(() => o.loadUser('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.changePassword('valor-de-prueba'));
      }
    });
  });
  test(
      'BackgroundTimeoutReconciler (core/services/background_timeout_reconciler.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f13.BackgroundTimeoutReconciler.instance);
      if (o != null) {
        await call(() => o.reconcile());
        await call(() => o.checkStatus());
      }
    });
  });
  test(
      'ReconciliationResult (core/services/background_timeout_reconciler.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f13.ReconciliationResult());
      if (o != null) {
        await call(() => o.totalProcessed);
        await call(() => o.hasErrors);
      }
    });
  });
  test('ReconciliationStats (core/services/background_timeout_reconciler.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f13.ReconciliationStats());
      if (o != null) {
        await call(() => o.totalPending);
        await call(() => o.needsReconciliation);
      }
    });
  });
  test('BoostService (core/services/boost_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f14.BoostService.instance);
      if (o != null) {
        await call(() => o.createBoost(
            workerId: '00000000-0000-4000-8000-0000000000aa',
            boostType: f14.BoostType.values.first,
            durationDays: 1));
        await call(() => o.hasActiveBoost(
            '00000000-0000-4000-8000-0000000000aa',
            f14.BoostType.values.first));
        await call(
            () => o.getActiveBoosts('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.cleanExpiredBoosts());
      }
    });
  });
  test('ChangeOrderService (core/services/change_order_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f15.ChangeOrderService.instance);
      if (o != null) {
        await call(() => o.submit(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            titulo: 'id-1',
            descripcion: 'id-1',
            montoClp: 1,
            tipo: 'id-1'));
        await call(() =>
            o.buildQuote(f16.ChangeOrderModel.fromMap(sampleChangeOrderModel)));
        await call(() => o.prepareWebpayCheckout(
            order: f16.ChangeOrderModel.fromMap(sampleChangeOrderModel),
            clientUserId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.reject(
            order: f16.ChangeOrderModel.fromMap(sampleChangeOrderModel),
            clientUserId: '00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('CrashReportingService (core/services/crash_reporting_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f17.CrashReportingService.instance);
      if (o != null) {
        await call(() => o.isInitialized);
        await call(() => o.initialize());
        await call(() => o.recordError(null, null,
            reason: 'id-1',
            fatal: true,
            additionalData: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.recordAppError(
            f18.AppError(message: 'id-1', originalError: null),
            stackTrace: null));
        await call(() => o.setUserId('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.setUserInfo(email: 'id-1', name: 'id-1', role: 'id-1'));
        await call(() => o.log('id-1'));
        await call(() => o.crash());
      }
    });
  });
  test('DemoTourService (core/services/demo_tour_service.dart)', () async {
    await forEachScenario(() async {
      await call(() => f19.DemoTourService.shouldShowHomeTour());
      await call(() => f19.DemoTourService.shouldShowWorkerHomeTour());
      await call(() => f19.DemoTourService.shouldShowWorkersTour());
      await call(() => f19.DemoTourService.shouldShowRequestTour());
      await call(() => f19.DemoTourService.completeHomeTour());
      await call(() => f19.DemoTourService.completeWorkerHomeTour());
      await call(() => f19.DemoTourService.completeWorkersTour());
      await call(() => f19.DemoTourService.completeRequestTour());
      await call(() => f19.DemoTourService.resetAllTours());
    });
  });
  test('DisputeService (core/services/dispute_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f20.DisputeService.instance);
      await call(() => f20.DisputeService.isOpenStatus('id-1'));
      if (o != null) {
        await call(() => o.openDispute(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            openedBy: 'id-1',
            reason: 'id-1',
            description: 'id-1'));
        await call(() => o.resolveDispute(
            disputeId: '00000000-0000-4000-8000-0000000000aa',
            resolvedBy: 'id-1',
            resolution: 'id-1',
            decision: 'id-1'));
        await call(() => o.appeal(
            disputeId: '00000000-0000-4000-8000-0000000000aa', motivo: 'id-1'));
        await call(() => o.addComment(
            disputeId: '00000000-0000-4000-8000-0000000000aa',
            comment: 'id-1'));
        await call(
            () => o.hasOpenDispute('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.canRateJob('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.proposeAgreement(
            jobId: '00000000-0000-4000-8000-0000000000aa', type: 'id-1'));
        await call(
            () => o.pendingAgreement('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.respondAgreement(
            id: '00000000-0000-4000-8000-0000000000aa', accept: true));
        await call(
            () => o.getDisputeByJobId('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('EvidenceStoragePath (core/services/evidence_storage_path.dart)',
      () async {
    await forEachScenario(() async {
      await call(() => f21.EvidenceStoragePath.mediaForMime('id-1'));
      await call(
          () => f21.EvidenceStoragePath.validate(mime: 'id-1', byteLength: 1));
      await call(() => f21.EvidenceStoragePath.objectPath(
          jobId: '00000000-0000-4000-8000-0000000000aa',
          userId: '00000000-0000-4000-8000-0000000000aa',
          fileId: '00000000-0000-4000-8000-0000000000aa',
          mime: 'id-1'));
      await call(() => f21.EvidenceStoragePath.isStoragePath('id-1'));
    });
  });
  test('SupabaseEvidenceGateway (core/services/evidence_uploader.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f22.SupabaseEvidenceGateway());
      if (o != null) {
        await call(
            () => o.upload('id-1', Uint8List.fromList([1, 2, 3, 4]), 'id-1'));
        await call(() => o.uploadFile('id-1', 'id-1', 'id-1'));
        await call(() => o.remove('id-1'));
        await call(() => o.insertRow(<String, dynamic>{'id': 'id-1'}));
        await call(() => o.signedUrl('id-1'));
      }
    });
  });
  test('EvidenceUploader (core/services/evidence_uploader.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f22.EvidenceUploader());
      if (o != null) {
        await call(() => o.save(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
            fileId: '00000000-0000-4000-8000-0000000000aa',
            bytes: Uint8List.fromList([1, 2, 3, 4]),
            mime: 'id-1',
            imageWebp: Uint8List.fromList([1, 2, 3, 4]),
            onProgress: (_) {}));
        await call(() => o.saveFile(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa',
            fileId: '00000000-0000-4000-8000-0000000000aa',
            filePath: 'id-1',
            byteLength: 1,
            mime: 'id-1',
            onProgress: (_) {}));
        await call(() => o.signedUrl('id-1'));
        await call(() => o.removeStored('id-1'));
      }
    });
  });
  test('EvidenceVideoLimits (core/services/evidence_video_limits.dart)',
      () async {
    await forEachScenario(() async {
      probe(() => f23.EvidenceVideoLimits());
      await call(() => f23.EvidenceVideoLimits.validate(
          byteLength: 1,
          duration: const Duration(milliseconds: 1),
          mime: 'id-1'));
    });
  });
  test('EvidenceVideoProvenance (core/services/evidence_video_limits.dart)',
      () async {
    await forEachScenario(() async {
      probe(() => f23.EvidenceVideoProvenance());
      await call(() => f23.EvidenceVideoProvenance.validate(
          nonce: 'id-1',
          hashSha256: 'id-1',
          byteLength: 1,
          duration: const Duration(milliseconds: 1),
          mime: 'id-1',
          lat: 1.0,
          lng: 1.0));
    });
  });
  test('FeatureFlagsService (core/services/feature_flags_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f24.FeatureFlagsService.instance);
      if (o != null) {
        await call(() => o.isEnabled('id-1'));
        await call(() => o.isEnabledFor(
            flagName: 'id-1',
            appVersion: 'id-1',
            role: 'id-1',
            userId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.setGlobalFlag('id-1', true));
        await call(() => o.setVersionFlag('id-1', 'id-1', true));
        await call(() => o.setRoleFlag('id-1', 'id-1', true));
        await call(() => o.setUserFlag(
            'id-1', '00000000-0000-4000-8000-0000000000aa', true));
        await call(() => o.getAllFlags());
        await call(() => o.initializeDefaultFlags());
        await call(() => o.syncFromServer());
      }
    });
  });
  test('GdprService (core/services/gdpr_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f25.GdprService.instance);
      if (o != null) {
        await call(() => o.recordConsent(
            userId: '00000000-0000-4000-8000-0000000000aa',
            accepted: true,
            ipAddress: 'id-1',
            userAgent: 'id-1'));
        await call(() =>
            o.hasAcceptedCurrentTerms('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.exportUserData('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.exportUserDataAsJson('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.requestAccountDeletion('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getConsentHistory('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('GpsPublishGate (core/services/gps_publish_gate.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f27.GpsPublishGate());
      if (o != null) {
        await call(() => o.shouldPublish(
            now: DateTime.utc(2026, 1, 2, 15), latitude: 1.0, longitude: 1.0));
      }
    });
  });
  test('JobBookingService (core/services/job_booking_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f28.JobBookingService.instance);
      if (o != null) {
        await call(() => o.createVisitBooking(
            userId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            address: 'id-1',
            visitFeeClp: 1,
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            description: 'id-1',
            comunaKey: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            transportExtraClp: 1));
        await call(() => o.createFixedSkuBooking(
            userId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            address: 'id-1',
            skuCode: 'id-1',
            visitFeeClp: 1,
            transportExtraClp: 1,
            description: 'id-1',
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            comunaKey: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            serviceMetadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.createWorkerTierBooking(
            userId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            address: 'id-1',
            tierOptionId: '00000000-0000-4000-8000-0000000000aa',
            tierLabel: 'id-1',
            amountClp: 1,
            description: 'id-1',
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            comunaKey: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            serviceMetadata: <String, dynamic>{'id': 'id-1'},
            priceUnit: 'id-1',
            squareMeters: 1,
            unitRateClp: 1,
            transportExtraClp: 1));
        await call(() => o.createHourlyBlockBooking(
            userId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            address: 'id-1',
            hourlyRateClp: 1,
            blockHours: 1,
            description: 'id-1',
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            comunaKey: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            serviceMetadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.createWorkerTierInvitation(
            userId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            address: 'id-1',
            tierOptionId: '00000000-0000-4000-8000-0000000000aa',
            tierLabel: 'id-1',
            amountClp: 1,
            description: 'id-1',
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            comunaKey: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            serviceMetadata: <String, dynamic>{'id': 'id-1'},
            priceUnit: 'id-1',
            squareMeters: 1,
            unitRateClp: 1,
            transportExtraClp: 1));
        await call(() => o.createOpenQuoteJob(
            userId: '00000000-0000-4000-8000-0000000000aa',
            invitedWorkerId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            address: 'id-1',
            description: 'id-1',
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            comunaKey: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            serviceMetadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.confirmCompletionAndPay(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.abandonUnpaidCheckout(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.confirmEscrowAndAccept(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            userId: '00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('JobCancellationService (core/services/job_cancellation_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f29.JobCancellationService());
      if (o != null) {
        await call(() => o.cancelJob(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            cancelledBy: 'id-1',
            reason: 'id-1',
            userRole: 'id-1'));
        await call(() => o.canCancelJob('00000000-0000-4000-8000-0000000000aa',
            '00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() =>
            o.getCancellationReason('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('JobService (core/services/job_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f30.JobService.instance);
      if (o != null) {
        await call(() => o.createJob(
            userId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            description: 'id-1',
            address: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            serviceMetadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.acceptJob(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.rejectJob(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.updateJobStatus(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            newStatus: 'id-1',
            userId: '00000000-0000-4000-8000-0000000000aa',
            pin: null));
        await call(() => o.getUserJobs('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getWorkerJobs('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getAvailableJobs());
        await call(() => o.getJobById('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('JobStateMachine (core/services/job_state_machine.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f31.JobStateMachine.instance);
      await call(() => f31.JobStateMachine.getFinalStates());
      await call(() => f31.JobStateMachine.isFinalState('id-1'));
      if (o != null) {
        await call(
            () => o.isValidTransition('id-1', 'id-1', pricingMode: 'id-1'));
        await call(() => o.transitionTo(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            newStatus: 'id-1',
            userId: '00000000-0000-4000-8000-0000000000aa',
            pin: 'id-1'));
        await call(() => o.processTimeouts());
        await call(() =>
            o.getSuggestedNextStatus(f32.JobModel.fromMap(sampleJobModel)));
        await call(() => o.canCancel(f32.JobModel.fromMap(sampleJobModel)));
        await call(() => o.canComplete(f32.JobModel.fromMap(sampleJobModel)));
      }
    });
  });
  test('JobTransitionMatrix (core/services/job_transition_matrix.dart)',
      () async {
    await forEachScenario(() async {
      await call(() => f33.JobTransitionMatrix.allowedTargets('id-1', 'id-1'));
      await call(
          () => f33.JobTransitionMatrix.isAllowed('id-1', 'id-1', 'id-1'));
    });
  });
  test('MatchingService (core/services/matching_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f35.MatchingService.instance);
      await call(
          () => f35.MatchingService.calculateDistance(1.0, 1.0, 1.0, 1.0));
      if (o != null) {
        await call(() => o.automaticMatching(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            userLatitude: 1.0,
            userLongitude: 1.0,
            maxResults: 1));
        await call(() => o.manualMatching(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            userLatitude: 1.0,
            userLongitude: 1.0,
            minRating: 1.0,
            maxDistanceKm: 1.0,
            onlyAvailable: true));
      }
    });
  });
  test(
      'NotificationPermissionGateway (core/services/notification_permission_gateway.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f38.NotificationPermissionGateway());
      if (o != null) {
        await call(() => o.request());
      }
    });
  });
  test(
      'NotificationRealtimeService (core/services/notification_realtime_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f39.NotificationRealtimeService.instance);
      if (o != null) {
        await call(() => o.onIncoming);
        await call(() => o.subscribe('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.unsubscribe());
      }
    });
  });
  test('NotificationService (core/services/notification_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f40.NotificationService.instance);
      if (o != null) {
        await call(() => o.initialize());
        await call(() => o.showNotification(
            title: 'id-1',
            body: 'id-1',
            userId: '00000000-0000-4000-8000-0000000000aa',
            type: 'id-1',
            relatedId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.notifyUsers(
            userIds: <String>['id-1'],
            title: 'id-1',
            body: 'id-1',
            type: 'id-1',
            relatedId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.showIncomingNotification(
            f41.NotificationModel.fromMap(sampleNotificationModel)));
        await call(() => o.scheduleNotification(
            title: 'id-1',
            body: 'id-1',
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            userId: '00000000-0000-4000-8000-0000000000aa',
            type: 'id-1',
            relatedId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.cancelNotification(1));
        await call(() => o.cancelAllNotifications());
      }
    });
  });
  test('OAuthDeepLinkService (core/services/oauth_deep_link_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f42.OAuthDeepLinkService.instance);
      if (o != null) {
        await call(() => o.expectOAuthCallback());
        await call(() => o.cancelOAuthCallback());
        await call(() => o.start(() async {}));
      }
    });
  });
  test(
      'OpenQuoteNotificationService (core/services/open_quote_notification_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f43.OpenQuoteNotificationService.instance);
      if (o != null) {
        await call(() => o.notifyInvitedWorker(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            jobRepository: f44.JobRepository(),
            jobLabel: 'id-1',
            isTierInvitation: true));
      }
    });
  });
  test('MockPaymentGateway (core/services/payment_gateway_port.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f45.MockPaymentGateway());
      if (o != null) {
        await call(() => o.authorizeHold(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            amountClp: 1,
            userId: '00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('PaymentGuard (core/services/payment_guard.dart)', () async {
    await forEachScenario(() async {
      await call(() => f46.PaymentGuard.validate(
          job: f32.JobModel.fromMap(sampleJobModel),
          targetStatus: 'id-1',
          ports: f47.PaymentGuardPorts(
              getPrimaryPayment: (_) async => null,
              hasAuthorizedPrimaryPayment: (_) async => true,
              countPendingChangeOrders: (_) async => 1,
              countApprovedUnpaidChangeOrders: (_) async => 1,
              countEvidence: (_) async => 1)));
      await call(
          () => f46.PaymentGuard.requiresAuthorizedForAccepted('id-1', 'id-1'));
      await call(() => f46.PaymentGuard.fromAwaitingPaymentToAccepted(
          f32.JobModel.fromMap(sampleJobModel), 'id-1'));
    });
  });
  test('PaymentService (core/services/payment_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f48.PaymentService.instance);
      if (o != null) {
        await call(() => o.createPayment(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            amount: 1.0,
            currency: 'id-1',
            paymentMethod: 'id-1'));
        await call(
            () => o.authorizePayment('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.holdPayment('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.resolveDisputeFunds(
            disputeId: '00000000-0000-4000-8000-0000000000aa',
            decision: 'id-1',
            resolution: 'id-1'));
        await call(() => o.refundBecauseWorkerRejected(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            metadata: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.releasePayment(
            '00000000-0000-4000-8000-0000000000aa',
            transferRef: 'id-1',
            notes: 'id-1'));
        await call(
            () => o.refundPayment('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getPrimaryPayment('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getPaymentByJobId('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.createSupplementalPayment(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            changeOrderId: '00000000-0000-4000-8000-0000000000aa',
            paymentType: 'id-1',
            quote: f49.PriceQuote.fromJson(samplePriceQuote),
            paymentMethod: 'id-1'));
        await call(() => o.createPrimaryPayment(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            quote: f49.PriceQuote.fromJson(samplePriceQuote),
            paymentMethod: 'id-1'));
        await call(() =>
            o.authorizePrimaryForJob('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.releasePrimaryOnJobCompleted(
            '00000000-0000-4000-8000-0000000000aa',
            transferRef: 'id-1',
            notes: 'id-1'));
        await call(() => o.refundPrimaryOnCancellation(
            '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.hasAuthorizedPrimaryPayment(
            '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.hasPayment('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.hasSavedCard(recoverAbandoned: true));
        await call(() => o.savedCard(recoverAbandoned: true));
        await call(() => o.removeSavedCard());
        await call(() => o.restoreReplacedCard());
        await call(() => o.startCardEnrollment(replacing: true));
        await call(() => o.chargeSavedCard(
            jobId: '00000000-0000-4000-8000-0000000000aa', amount: 1.0));
        await call(
            () => o.previewJobCharge('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.initiateWebpayPayment(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            amount: 1.0,
            changeOrderId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.webpayCheckoutSettled('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.confirmWebpayPayment(token: 'id-1'));
      }
    });
  });
  test('PhotoService (core/services/photo_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f51.PhotoService.instance);
      if (o != null) {
        await call(() => o.pickImage());
        await call(() => o.compressImage(File('/tmp/no-existe.jpg')));
        await call(() => o.saveJobPhoto(File('/tmp/no-existe.jpg'),
            '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.saveProfilePhoto(File('/tmp/no-existe.jpg'),
            '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.savePortfolioPhoto(File('/tmp/no-existe.jpg'),
            '00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.deleteJobPhotos('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.deletePortfolioPhotos('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.getFileSizeKB('id-1'));
        await call(() => o.fileExists('id-1'));
      }
    });
  });
  test('PricingGuardService (core/services/pricing_guard_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f52.PricingGuardService.instance);
      if (o != null) {
        await call(() => o.checkPrice(
            serviceId: '00000000-0000-4000-8000-0000000000aa', price: 1.0));
      }
    });
  });
  test(
      'PricingModeQuestionnaireService (core/services/pricing_mode_questionnaire_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f53.PricingModeQuestionnaireService.instance);
      if (o != null) {
        await call(() => o.recommend(
            jobType: 'id-1',
            repairType: 'id-1',
            blockHours: 1,
            workerPreselected: true));
      }
    });
  });
  test('PricingService (core/services/pricing_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f54.PricingService.instance);
      if (o != null) {
        await call(() => o.calculateWorkerTierPrice(
            optionId: '00000000-0000-4000-8000-0000000000aa',
            optionLabel: 'id-1',
            amountClp: 1,
            comunaKey: 'id-1',
            unit: f55.WorkerPriceUnit.values.first,
            squareMeters: 1,
            unitRateClp: 1,
            transportExtraClp: 1));
        await call(() => o.calculateFixedPrice(
            skuCode: 'id-1', comunaKey: 'id-1', comunaSurchargeClp: 1));
        await call(() => o.calculateHourlyBlock(
            hourlyRateClp: 1, blockHours: 1, comunaKey: 'id-1'));
        await call(() => o.calculateVisitBooking(
            visitFeeClp: 1, comunaKey: 'id-1', transportExtraClp: 1));
        await call(() => o.calculateHourlyOvertime(
            hourlyRateClp: 1, extraHours: 1, comunaKey: 'id-1'));
        await call(() => o.estimateHourlyRateFromVisitFee(1));
        await call(() => o.serviceFeeFor(1));
        await call(() => o.applyServerCharge(
            f49.PriceQuote.fromJson(samplePriceQuote),
            f56.JobChargePreview.fromMap(sampleJobChargePreview)));
        await call(() => o.alignToChargedTotal(
            f49.PriceQuote.fromJson(samplePriceQuote), 1));
        await call(() =>
            o.quoteFromOpenProposal(proposalAmountClp: 1, platformFeeClp: 1));
      }
    });
  });
  test('ProfilePhotoService (core/services/profile_photo_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f57.ProfilePhotoService.instance);
      if (o != null) {
        await call(() => o.removePhoto('id-1'));
      }
    });
  });
  test('LocalOnlyPushNotifications (core/services/push_notification_port.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f58.LocalOnlyPushNotifications());
      if (o != null) {
        await call(() => o.initialize());
        await call(() => o.getDeviceToken());
        await call(() => o.showLocal(title: 'id-1', body: 'id-1'));
      }
    });
  });
  test(
      'UnimplementedFcmPushNotifications (core/services/push_notification_port.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f58.UnimplementedFcmPushNotifications());
      if (o != null) {
        await call(() => o.initialize());
        await call(() => o.getDeviceToken());
        await call(() => o.showLocal(title: 'id-1', body: 'id-1'));
      }
    });
  });
  test('PushService (core/services/push_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f59.PushService.instance);
      if (o != null) {
        await call(() => o.register('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.unregister());
      }
    });
  });
  test('QuoteProposalService (core/services/quote_proposal_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f60.QuoteProposalService.instance);
      if (o != null) {
        await call(() => o.listForJob('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.submit(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa',
            montoTotalClp: 1,
            descripcion: 'id-1',
            validezDias: 1,
            materialesClp: 1,
            manoObraClp: 1,
            horasEstimadas: 1));
        await call(() => o.selectProposal(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            proposalId: '00000000-0000-4000-8000-0000000000aa',
            clientUserId: '00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.withdraw(
            proposalId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('RateLimiterService (core/services/rate_limiter_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f61.RateLimiterService.instance);
      await call(() => f61.RateLimiterService.getRateLimitMessage(
          f61.RateLimitResult(
              allowed: true,
              timeUntilReset: const Duration(milliseconds: 1),
              limit: 1,
              window: const Duration(milliseconds: 1))));
      if (o != null) {
        await call(() => o.canPerformAction(
            userId: '00000000-0000-4000-8000-0000000000aa',
            action: f61.RateLimitAction.values.first));
        await call(() => o.recordAction(
            userId: '00000000-0000-4000-8000-0000000000aa',
            action: f61.RateLimitAction.values.first));
        await call(() => o.clearHistory(
            userId: '00000000-0000-4000-8000-0000000000aa',
            action: f61.RateLimitAction.values.first));
      }
    });
  });
  test('ReportService (core/services/report_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f62.ReportService());
      if (o != null) {
        await call(() => o.createReport(
            reporterId: '00000000-0000-4000-8000-0000000000aa',
            reportedUserId: '00000000-0000-4000-8000-0000000000aa',
            reason: 'id-1',
            description: 'id-1'));
        await call(() =>
            o.getReportsByReporter('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getReportsAboutUser('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('ServiceLegalValidator (core/services/service_legal_validator.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f63.ServiceLegalValidator.instance);
      await call(() => f63.ServiceLegalValidator.formatClp(1));
      await call(
          () => f63.ServiceLegalValidator.paymentNotice(chargeAmountClp: 1));
      if (o != null) {
        await call(
            () => o.validateService('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.validateServiceRestrictions(
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            serviceData: <String, dynamic>{'id': 'id-1'}));
        await call(() => o.buildConfirmationText(
            serviceId: '00000000-0000-4000-8000-0000000000aa',
            serviceName: 'id-1'));
        await call(() =>
            o.getServiceDisclaimer('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('SessionManager (core/services/session_manager.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f64.SessionManager.instance);
      if (o != null) {
        await call(() =>
            o.saveSession('00000000-0000-4000-8000-0000000000aa', 'id-1'));
        await call(() => o.restoreSession());
        await call(() => o.getSavedRole());
        await call(() => o.clearSession());
        await call(() => o.hasActiveSession());
        await call(() => o.getSessionData());
      }
    });
  });
  test('SubscriptionService (core/services/subscription_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f65.SubscriptionService.instance);
      if (o != null) {
        await call(() => o.createSubscription(
            userId: '00000000-0000-4000-8000-0000000000aa',
            plan: f65.SubscriptionPlan.values.first,
            durationDays: 1));
        await call(() =>
            o.hasActiveSubscription('00000000-0000-4000-8000-0000000000aa'));
        await call(() =>
            o.getActiveSubscription('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.cancelSubscription('00000000-0000-4000-8000-0000000000aa'));
        await call(() => o.checkExpiredSubscriptions());
      }
    });
  });
  test('TestingSurvey (core/services/testing_feedback_store.dart)', () async {
    await forEachScenario(() async {
      await call(() => f66.TestingSurvey.susScore(<int>[1]));
    });
  });
  test('TestingFeedbackDraft (core/services/testing_feedback_store.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() =>
          f66.TestingFeedbackDraft(score: 1, worked: 'id-1', improve: 'id-1'));
      if (o != null) {
        await call(() => o.susAnswered);
        await call(() => o.isValid);
        await call(() => o.toJson());
        await call(() => o.toRpcParams(appVersion: 'id-1'));
      }
    });
  });
  test('TestingFeedbackStore (core/services/testing_feedback_store.dart)',
      () async {
    await forEachScenario(() async {
      await call(() => f66.TestingFeedbackStore.save(
          f66.TestingFeedbackDraft(score: 1, worked: 'id-1', improve: 'id-1')));
      await call(() => f66.TestingFeedbackStore.saveLocal(
          f66.TestingFeedbackDraft(score: 1, worked: 'id-1', improve: 'id-1')));
      await call(() => f66.TestingFeedbackStore.readAll());
    });
  });
  test('TransbankWebpayGateway (core/services/transbank_webpay_gateway.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f67.TransbankWebpayGateway());
      if (o != null) {
        await call(() => o.authorizeHold(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            amountClp: 1,
            userId: '00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('TrustScoreService (core/services/trust_score_service.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f68.TrustScoreService.instance);
      if (o != null) {
        await call(() =>
            o.calculateTrustScore('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.canCancelJob('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.isSoftBanned('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.recordCancellation('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.recordNoShow('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.recordCompletedJob('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getWarningMessage('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test('UserLocationService (core/services/user_location_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f69.UserLocationService.instance);
      await call(() => f69.UserLocationService.resolvePoint(
          latitude: 1.0,
          longitude: 1.0,
          city: 'id-1',
          region: 'id-1',
          remapOutsideChile: true));
      if (o != null) {
        await call(
            () => o.currentPosition(timeout: const Duration(milliseconds: 1)));
        await call(() => o.resolve());
        await call(() => o.getCached());
        await call(() => o.persist(f70.UserLocationContext(city: 'id-1')));
        await call(() => o.getCurrent());
        await call(() => o.fromCoordinates(1.0, 1.0, remapOutsideChile: true));
        await call(() => o.fromAddress('id-1'));
        await call(() => o.setManualCity('id-1', region: 'id-1'));
      }
    });
  });
  test('WorkerEarningsService (core/services/worker_earnings_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f71.WorkerEarningsService.instance);
      if (o != null) {
        await call(() => o.getSnapshot('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test(
      'WorkerJobRejectionService (core/services/worker_job_rejection_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f72.WorkerJobRejectionService.instance);
      if (o != null) {
        await call(() => o.rejectAndSuggestAlternatives(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            workerId: '00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.alternativesForJob(f32.JobModel.fromMap(sampleJobModel)));
      }
    });
  });
  test(
      'WorkerOnboardingChecklistService (core/services/worker_onboarding_checklist_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f73.WorkerOnboardingChecklistService.instance);
      if (o != null) {
        await call(() => o.checkStatus('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.canReceiveJobs('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.isListedInSearch('00000000-0000-4000-8000-0000000000aa'));
        await call(
            () => o.getNextPendingStep('00000000-0000-4000-8000-0000000000aa'));
      }
    });
  });
  test(
      'WorkerOnboardingStatus (core/services/worker_onboarding_checklist_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f73.WorkerOnboardingStatus(
          isComplete: true,
          completionPercentage: 1,
          missingItems: <String>['id-1']));
      if (o != null) {
        await call(() => o.toMap());
      }
    });
  });
  test('WorkerReputationService (core/services/worker_reputation_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f74.WorkerReputationService.instance);
      if (o != null) {
        await call(
            () => o.listingScore(f5.WorkerModel.fromMap(sampleWorkerModel)));
        await call(() => o.sortForListing(
            [f5.WorkerModel.fromMap(sampleWorkerModel)],
            clientLatitude: 1.0, clientLongitude: 1.0));
      }
    });
  });
  test('WorkerSearchService (core/services/worker_search_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f75.WorkerSearchService());
      await call(
          () => f75.WorkerSearchService.calculateDistance(1.0, 1.0, 1.0, 1.0));
      if (o != null) {
        await call(() => o.searchWorkers(
            query: 'id-1',
            filters: f75.WorkerSearchFilters(),
            sortBy: f75.WorkerSortOption.values.first,
            userLatitude: 1.0,
            userLongitude: 1.0));
      }
    });
  });
}
