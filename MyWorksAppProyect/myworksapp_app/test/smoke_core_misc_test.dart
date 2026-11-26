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
import 'package:myworksapp/bootstrap/app_initializer.dart' as f0;
import 'package:myworksapp/core/config/demo_catalog_config.dart' as f1;
import 'package:myworksapp/core/config/demo_credentials.dart' as f2;
import 'package:myworksapp/core/config/demo_free_media.dart' as f3;
import 'package:myworksapp/core/config/oauth_config.dart' as f4;
import 'package:myworksapp/core/config/push_config.dart' as f5;
import 'package:myworksapp/core/config/supabase_config.dart' as f6;
import 'package:myworksapp/core/config/support_config.dart' as f7;
import 'package:myworksapp/core/design_system/app_breakpoints.dart' as f8;
import 'package:myworksapp/core/design_system/app_elevation.dart' as f9;
import 'package:myworksapp/core/design_system/app_radius.dart' as f10;
import 'package:myworksapp/core/design_system/app_spacing.dart' as f11;
import 'package:myworksapp/core/design_system/layout_utils.dart' as f12;
import 'package:myworksapp/core/domain/booking_schedule.dart' as f13;
import 'package:myworksapp/core/domain/catalog_order.dart' as f14;
import 'package:myworksapp/core/domain/distance_match.dart' as f15;
import 'package:myworksapp/core/domain/generated_domain.dart' as f16;
import 'package:myworksapp/core/domain/job_charge_preview.dart' as f17;
import 'package:myworksapp/core/domain/payout_summary.dart' as f18;
import 'package:myworksapp/core/domain/price_quote.dart' as f19;
import 'package:myworksapp/core/domain/pricing_constants.dart' as f20;
import 'package:myworksapp/core/domain/pricing_mode_recommendation.dart' as f21;
import 'package:myworksapp/core/domain/reschedule_rules.dart' as f22;
import 'package:myworksapp/core/domain/transport_surcharge.dart' as f23;
import 'package:myworksapp/core/domain/user_location_context.dart' as f24;
import 'package:myworksapp/core/domain/webpay_transaction.dart' as f25;
import 'package:myworksapp/core/domain/weekly_schedule.dart' as f26;
import 'package:myworksapp/core/domain/worker_charge.dart' as f27;
import 'package:myworksapp/core/domain/worker_custom_service.dart' as f28;
import 'package:myworksapp/core/domain/worker_service_options_catalog.dart'
    as f29;
import 'package:myworksapp/core/domain/worker_earnings_snapshot.dart' as f30;
import 'package:myworksapp/core/domain/worker_highlight.dart' as f31;
import 'package:myworksapp/core/domain/worker_hours.dart' as f32;
import 'package:myworksapp/core/domain/worker_login_item.dart' as f33;
import 'package:myworksapp/core/domain/worker_public_stats.dart' as f34;
import 'package:myworksapp/core/database/models/worker_model.dart' as f35;
import 'package:myworksapp/core/dto/job_dto.dart' as f36;
import 'package:myworksapp/core/exceptions/auth_exceptions.dart' as f37;
import 'package:myworksapp/core/interfaces/analytics_repository_interface.dart'
    as f38;
import 'package:myworksapp/core/database/models/analytics_event_model.dart'
    as f39;
import 'package:myworksapp/core/interfaces/repository_interface.dart' as f40;
import 'package:myworksapp/core/map/app_map_tiles.dart' as f41;
import 'package:myworksapp/core/providers/auth_provider.dart' as f42;
import 'package:myworksapp/core/database/models/user_model.dart' as f43;
import 'package:myworksapp/core/theme/app_colors.dart' as f44;
import 'package:myworksapp/core/theme/app_decorations.dart' as f45;
import 'package:myworksapp/core/theme/app_text_styles.dart' as f46;
import 'package:myworksapp/core/theme/app_theme.dart' as f47;
import 'package:myworksapp/core/theme/generated_brand_colors.dart' as f48;
import 'package:myworksapp/core/theme/service_card_palettes.dart' as f49;
import 'package:myworksapp/core/utils/app_error.dart' as f50;
import 'package:myworksapp/core/utils/app_logger.dart' as f51;
import 'package:myworksapp/core/utils/app_media_permissions.dart' as f52;
import 'package:myworksapp/core/utils/app_text_scaling.dart' as f53;
import 'package:myworksapp/core/utils/chile_comunas.dart' as f54;
import 'package:myworksapp/core/utils/clp_format.dart' as f55;
import 'package:myworksapp/core/utils/constants.dart' as f56;
import 'package:myworksapp/core/utils/debouncer.dart' as f57;
import 'package:myworksapp/core/utils/error_handler.dart' as f58;
import 'package:myworksapp/core/utils/external_map_launcher.dart' as f59;
import 'package:myworksapp/core/utils/job_display_utils.dart' as f60;
import 'package:myworksapp/core/database/models/job_model.dart' as f61;
import 'package:myworksapp/core/utils/job_schedule_grouping.dart' as f62;
import 'package:myworksapp/core/utils/job_status_copy.dart' as f63;
import 'package:myworksapp/core/utils/location_utils.dart' as f64;
import 'package:myworksapp/core/utils/memo_cache.dart' as f65;
import 'package:myworksapp/core/utils/mock_reserved_slots.dart' as f66;
import 'package:myworksapp/core/utils/open_quote_utils.dart' as f67;
import 'package:myworksapp/core/utils/platform_support.dart' as f68;
import 'package:myworksapp/core/utils/portfolio_media_resolver.dart' as f69;
import 'package:myworksapp/core/utils/santiago_time.dart' as f70;
import 'package:myworksapp/core/utils/service_worker_mapper.dart' as f71;
import 'package:myworksapp/core/utils/validators.dart' as f72;
import 'package:myworksapp/core/utils/worker_job_status.dart' as f73;
import 'package:myworksapp/core/utils/worker_zone_matcher.dart' as f74;
import 'package:myworksapp/features/chat/domain/conversation_preview.dart'
    as f75;
import 'package:myworksapp/features/jobs/presentation/utils/job_detail_helpers.dart'
    as f76;
import 'package:myworksapp/core/database/models/dispute_model.dart' as f77;
import 'package:myworksapp/features/notifications/domain/notification_groups.dart'
    as f78;
import 'package:myworksapp/core/database/models/notification_model.dart' as f79;
import 'package:myworksapp/features/ratings/domain/rating_gate.dart' as f80;
import 'package:myworksapp/features/worker/presentation/providers/worker_home_refresh_provider.dart'
    as f81;
import 'package:myworksapp/utils/content_filter.dart' as f82;
import 'support/model_samples.dart';
import 'support/scenarios.dart';

void main() {
  setUpAll(setUpScenarios);
  test('AppInitializer (bootstrap/app_initializer.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f0.AppInitializer.instance);
      if (o != null) {
        await call(() => o.lastResult);
        await call(() => o.isInitialized);
        await call(() => o.reset());
      }
    });
  });
  test('DemoCredentials (core/config/demo_credentials.dart)', () async {
    await forEachScenario(() async {
      probe(() => f2.DemoCredentials());
      await call(() => f2.DemoCredentials.isDemoEmail('id-1'));
    });
  });
  test('DemoFreeMedia (core/config/demo_free_media.dart)', () async {
    await forEachScenario(() async {
      await call(() => f3.DemoFreeMedia.url('id-1'));
      await call(() => f3.DemoFreeMedia.profileForWorker(
          '00000000-0000-4000-8000-0000000000aa'));
      await call(() => f3.DemoFreeMedia.profileForDemoUser());
      await call(() => f3.DemoFreeMedia.portfolioForKey('id-1'));
      await call(() => f3.DemoFreeMedia.portfolioThumbnailForKey('id-1'));
      await call(() => f3.DemoFreeMedia.portfolioVideoForKey('id-1'));
      await call(() => f3.DemoFreeMedia.shouldReplaceDemoPortfolioPath('id-1'));
      await call(() => f3.DemoFreeMedia.shouldReplaceDemoPhoto('id-1'));
    });
  });
  test('OAuthConfig (core/config/oauth_config.dart)', () async {
    await forEachScenario(() async {
      await call(() => f4.OAuthConfig.isOAuthCallback(
          Uri.parse('https://example.invalid/x')));
    });
  });
  test('PushConfig (core/config/push_config.dart)', () async {
    await forEachScenario(() async {
      await call(() => f5.PushConfig.isConfigured);
      await call(() => f5.PushConfig.isSupportedPlatform);
      await call(() => f5.PushConfig.isEnabled);
      await call(() => f5.PushConfig.options);
    });
  });
  test('SupabaseConfig (core/config/supabase_config.dart)', () async {
    await forEachScenario(() async {
      await call(() => f6.SupabaseConfig.validateForCurrentBuild());
    });
  });
  test('SupportConfig (core/config/support_config.dart)', () async {
    await forEachScenario(() async {
      await call(() => f7.SupportConfig.hasEmail);
      await call(() => f7.SupportConfig.hasWhatsapp);
      await call(() => f7.SupportConfig.whatsappLabel);
      await call(
          () => f7.SupportConfig.emailUri(subject: 'id-1', body: 'id-1'));
      await call(() => f7.SupportConfig.whatsappUri('id-1'));
    });
  });
  test('LayoutUtils (core/design_system/layout_utils.dart)', () async {
    await forEachScenario(() async {
      await call(() => f12.LayoutUtils.screenHorizontal);
    });
  });
  test('BookingSchedule (core/domain/booking_schedule.dart)', () async {
    await forEachScenario(() async {
      await call(
          () => f13.BookingSchedule.dateOnly(DateTime.utc(2026, 1, 2, 15)));
    });
  });
  test('GeneratedWorkerActiveJobStatuses (core/domain/generated_domain.dart)',
      () async {
    await forEachScenario(() async {
      await call(() => f16.GeneratedWorkerActiveJobStatuses.contains('id-1'));
    });
  });
  test('PayoutMovement (core/domain/payout_summary.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f18.PayoutMovement(
          paymentId: 'id-1',
          jobId: 'id-1',
          amountClp: 1,
          paymentStatus: 'id-1'));
      if (o != null) {
        await call(() => o.isTransferred);
        await call(() => o.countsAsPending);
      }
    });
  });
  test('PayoutSummary (core/domain/payout_summary.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f18.PayoutSummary(movements: [
            f18.PayoutMovement(
                paymentId: 'id-1',
                jobId: 'id-1',
                amountClp: 1,
                paymentStatus: 'id-1')
          ]));
      if (o != null) {
        await call(() => o.pendingClp);
        await call(() => o.pendingGrossClp);
        await call(() => o.pendingFeeClp);
        await call(() => o.transferredClp);
        await call(() => o.transferredGrossClp);
        await call(() => o.transferredFeeClp);
        await call(() => o.history);
      }
    });
  });
  test('PriceQuote (core/domain/price_quote.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f19.PriceQuote.fromJson(samplePriceQuote));
      if (o != null) {
        await call(() => o.feeDeductedFromWorker);
        await call(() => o.toJson());
        await call(() => o.toJobMetadata());
      }
    });
  });
  test('PricingConstants (core/domain/pricing_constants.dart)', () async {
    await forEachScenario(() async {
      await call(() => f20.PricingConstants.isEscrowSecured('id-1'));
    });
  });
  test(
      'PricingModeRecommendation (core/domain/pricing_mode_recommendation.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f21.PricingModeRecommendation(
          mode: 'id-1', title: 'id-1', explanation: 'id-1'));
      if (o != null) {
        await call(() => o.needsWorker);
        await call(() => o.copyWith(
            mode: 'id-1',
            title: 'id-1',
            explanation: 'id-1',
            skuCode: 'id-1',
            variantKey: 'id-1',
            blockHours: 1,
            questionnaireAnswers: <String, dynamic>{'id': 'id-1'}));
      }
    });
  });
  test('RescheduleProposal (core/domain/reschedule_rules.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f22.RescheduleProposal.fromMap(sampleRescheduleProposal));
      if (o != null) {
        await call(() => o.isPending);
      }
    });
  });
  test('RescheduleRules (core/domain/reschedule_rules.dart)', () async {
    await forEachScenario(() async {
      await call(() => f22.RescheduleRules.canPropose(
          status: 'id-1',
          scheduledAt: DateTime.utc(2026, 1, 2, 15),
          workerId: '00000000-0000-4000-8000-0000000000aa',
          now: DateTime.utc(2026, 1, 2, 15)));
      await call(() => f22.RescheduleRules.slotOptions(<DateTime>[
            DateTime.utc(2026, 1, 2, 15)
          ], DateTime.utc(2026, 1, 2, 15), now: DateTime.utc(2026, 1, 2, 15)));
      await call(() => f22.RescheduleRules.canRespond(
          f22.RescheduleProposal.fromMap(sampleRescheduleProposal),
          '00000000-0000-4000-8000-0000000000aa'));
      await call(() => f22.RescheduleRules.statusLabel('id-1'));
    });
  });
  test('UserLocationContext (core/domain/user_location_context.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f24.UserLocationContext(city: 'id-1'));
      if (o != null) {
        await call(() => o.displayLabel);
      }
    });
  });
  test('WebpayCommitResult (core/domain/webpay_transaction.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f25.WebpayCommitResult.fromMap(sampleWebpayCommitResult));
      if (o != null) {
        await call(() => o.rejected);
      }
    });
  });
  test('TimeRange (core/domain/weekly_schedule.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f26.TimeRange(startMinute: 1, endMinute: 1));
      if (o != null) {
        await call(() => o.isValid);
        await call(() => o.containsMinute(1));
        await call(() => o.copyWith(startMinute: 1, endMinute: 1));
      }
    });
  });
  test('DayWindow (core/domain/weekly_schedule.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f26.DayWindow(weekday: 1, startMinute: 1, endMinute: 1));
      if (o != null) {
        await call(() => o.windows);
        await call(() => o.containsMinute(1));
        await call(() => o.copyWith(
            weekday: 1,
            startMinute: 1,
            endMinute: 1,
            enabled: true,
            ranges: [f26.TimeRange(startMinute: 1, endMinute: 1)]));
      }
    });
  });
  test('WeeklySchedule (core/domain/weekly_schedule.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f26.WeeklySchedule(enabled: true));
      await call(() => f26.WeeklySchedule.weekdaysNineToSix());
      if (o != null) {
        await call(() => o.restricts);
        await call(() => o.windowFor(1));
      }
    });
  });
  test('WorkerCustomService (core/domain/worker_custom_service.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(
          () => f28.WorkerCustomService.fromMap(sampleWorkerCustomService));
      await call(() => f28.WorkerCustomService.listFromJson(null));
      if (o != null) {
        await call(() => o.toMap());
        await call(() => o.copyWith(
            title: 'id-1',
            subtitle: 'id-1',
            priceClp: 1,
            unit: f29.WorkerPriceUnit.values.first));
        await call(() => o.toOptionDef());
      }
    });
  });
  test('WorkerEarningsSnapshot (core/domain/worker_earnings_snapshot.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f30.WorkerEarningsSnapshot(
          escrowClp: 1, releasedClp: 1, pendingClp: 1, paymentCount: 1));
      if (o != null) {
        await call(() => o.totalRecordedClp);
      }
    });
  });
  test('WorkerHourSlot (core/domain/worker_hours.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f32.WorkerHourSlot(weekday: 1, time: 'id-1'));
      if (o != null) {
        await call(() => o.toJson());
      }
    });
  });
  test('WorkerPublicStats (core/domain/worker_public_stats.dart)', () async {
    await forEachScenario(() async {
      probe(() => f34.WorkerPublicStats.fromMap(sampleWorkerPublicStats));
      await call(() => f34.WorkerPublicStats.ratingLabel(1.0, ratingCount: 1));
    });
  });
  test(
      'WorkerServiceOptionsCatalog (core/domain/worker_service_options_catalog.dart)',
      () async {
    await forEachScenario(() async {
      await call(() => f29.WorkerServiceOptionsCatalog.optionsFor('id-1'));
      await call(() => f29.WorkerServiceOptionsCatalog.defaultTiersFor('id-1'));
      await call(
          () => f29.WorkerServiceOptionsCatalog.catalogOptionsFor('id-1'));
      await call(
          () => f29.WorkerServiceOptionsCatalog.pricingOptionsFor('id-1'));
      await call(() =>
          f29.WorkerServiceOptionsCatalog.largeProjectClientOption('id-1'));
      await call(() =>
          f29.WorkerServiceOptionsCatalog.perSqmTierIdForCategory('id-1'));
      await call(() => f29.WorkerServiceOptionsCatalog.visitOption());
      await call(() => f29.WorkerServiceOptionsCatalog.clientOptionsFor(
          f35.WorkerModel.fromMap(sampleWorkerModel)));
      await call(() => f29.WorkerServiceOptionsCatalog.customOptionsFor(
          f35.WorkerModel.fromMap(sampleWorkerModel)));
      await call(() =>
          f29.WorkerServiceOptionsCatalog.categorySupportsLargeProjects(
              'id-1'));
      await call(() => f29.WorkerServiceOptionsCatalog.findOption(
          'id-1', '00000000-0000-4000-8000-0000000000aa'));
      await call(() => f29.WorkerServiceOptionsCatalog.findOptionForWorker(
          f35.WorkerModel.fromMap(sampleWorkerModel),
          '00000000-0000-4000-8000-0000000000aa'));
    });
  });
  test('JobDTO (core/dto/job_dto.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f36.JobDTO.fromJson(sampleJobDTO));
      if (o != null) {
        await call(() => o.toJson());
      }
    });
  });
  test('MapTileCache (core/map/app_map_tiles.dart)', () async {
    await forEachScenario(() async {
      await call(() => f41.MapTileCache.keyOf('id-1'));
      await call(() => f41.MapTileCache.osmUrlFor('id-1'));
      await call(() => f41.MapTileCache.get('id-1'));
      await call(
          () => f41.MapTileCache.put('id-1', Uint8List.fromList([1, 2, 3, 4])));
      await call(() => f41.MapTileCache.markServed());
      await call(() => f41.MapTileCache.whenServed(() {}));
      await call(() => f41.MapTileCache.cancel(() {}));
      await call(() => f41.MapTileCache.debugReset());
    });
  });
  test('AuthState (core/providers/auth_provider.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f42.AuthState());
      if (o != null) {
        await call(() => o.isAuthenticated);
        await call(() => o.role);
        await call(() => o.copyWith(
            user: f43.UserModel.fromMap(sampleUserModel),
            isLoading: true,
            error: 'id-1',
            clearUser: true,
            recoveringPassword: true));
      }
    });
  });
  test('AppColors (core/theme/app_colors.dart)', () async {
    await forEachScenario(() async {
      await call(() =>
          f44.AppColors.getTextColorForBackground(const Color(0xFF000000)));
      await call(() => f44.AppColors.getSurfaceColor(true));
      await call(() => f44.AppColors.getBackgroundColor(true));
    });
  });
  test('AppDecorations (core/theme/app_decorations.dart)', () async {
    await forEachScenario(() async {
      await call(() => f45.AppDecorations.headerShadow);
      await call(() => f45.AppDecorations.appleCardShadow(
          accent: const Color(0xFF000000), isDark: true));
      await call(() => f45.AppDecorations.cardShadow(const Color(0xFF000000)));
      await call(() => f45.AppDecorations.surfaceCard(
          accent: const Color(0xFF000000),
          radius: 1.0,
          isDark: true,
          overrideColor: const Color(0xFF000000)));
      await call(
          () => f45.AppDecorations.glassPanel(radius: 1.0, isDark: true));
    });
  });
  test('AppTextStyles (core/theme/app_text_styles.dart)', () async {
    await forEachScenario(() async {
      await call(
          () => f46.AppTextStyles.displayLarge(color: const Color(0xFF000000)));
      await call(() =>
          f46.AppTextStyles.displayMedium(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.displaySmall(color: const Color(0xFF000000)));
      await call(() =>
          f46.AppTextStyles.headlineLarge(color: const Color(0xFF000000)));
      await call(() =>
          f46.AppTextStyles.headlineMedium(color: const Color(0xFF000000)));
      await call(() =>
          f46.AppTextStyles.headlineSmall(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.titleLarge(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.titleMedium(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.titleSmall(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.bodyLarge(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.bodyMedium(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.bodySmall(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.labelLarge(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.labelMedium(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.labelSmall(color: const Color(0xFF000000)));
      await call(() =>
          f46.AppTextStyles.buttonPrimary(color: const Color(0xFF000000)));
      await call(() =>
          f46.AppTextStyles.buttonSecondary(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.inputLabel(color: const Color(0xFF000000)));
      await call(
          () => f46.AppTextStyles.inputHint(color: const Color(0xFF000000)));
    });
  });
  test('AppTheme (core/theme/app_theme.dart)', () async {
    await forEachScenario(() async {
      await call(() => f47.AppTheme.lightTheme);
      await call(() => f47.AppTheme.darkTheme);
      await call(() => f47.AppTheme.screenPadding);
      await call(() => f47.AppTheme.cardPadding);
    });
  });
  test('ServiceCardPalette (core/theme/service_card_palettes.dart)', () async {
    await forEachScenario(() async {
      probe(() => f49.ServiceCardPalette(
          background: const Color(0xFF000000),
          iconBackground: const Color(0xFF000000),
          accent: const Color(0xFF000000)));
      await call(() => f49.ServiceCardPalette.forCategory('id-1'));
    });
  });
  test('AppLogger (core/utils/app_logger.dart)', () async {
    await forEachScenario(() async {
      probe(() => f51.AppLogger());
      await call(() => f51.AppLogger.instance);
      await call(() => f51.AppLogger.d('id-1', null, null));
      await call(() => f51.AppLogger.i('id-1', null, null));
      await call(() => f51.AppLogger.w('id-1', null, null));
      await call(() => f51.AppLogger.e('id-1', null, null));
      await call(() => f51.AppLogger.f('id-1', null, null));
    });
  });
  test('AppMediaPermissions (core/utils/app_media_permissions.dart)', () async {
    await forEachScenario(() async {
      await call(() => f52.AppMediaPermissions.galleryRead);
      await call(() => f52.AppMediaPermissions.requestGalleryAccess());
      await call(() => f52.AppMediaPermissions.isGalleryGranted());
    });
  });
  test('ChileComunas (core/utils/chile_comunas.dart)', () async {
    await forEachScenario(() async {
      await call(() => f54.ChileComunas.allZones);
      await call(() => f54.ChileComunas.isMetropolitanComuna('id-1'));
      await call(() => f54.ChileComunas.isMetropolitanRegion('id-1'));
      await call(() => f54.ChileComunas.isServiceCity('id-1'));
      await call(() => f54.ChileComunas.inChile(1.0, 1.0));
      await call(() => f54.ChileComunas.regionOf('id-1'));
      await call(() => f54.ChileComunas.nearestServiceCity(1.0, 1.0));
      await call(() => f54.ChileComunas.catalogCity('id-1',
          region: 'id-1', latitude: 1.0, longitude: 1.0));
    });
  });
  test('ClpFormat (core/utils/clp_format.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f55.ClpFormat());
      if (o != null) {
        await call(() => o.format(1));
      }
    });
  });
  test('Debouncer (core/utils/debouncer.dart)', () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f57.Debouncer());
      if (o != null) {
        await call(() => o.isPending);
        await call(() => o.run(() {}));
        await call(() => o.cancel());
      }
    });
  });
  test('ErrorHandler (core/utils/error_handler.dart)', () async {
    await forEachScenario(() async {
      probe(() => f58.ErrorHandler());
      await call(() => f58.ErrorHandler.handle(null));
      await call(() => f58.ErrorHandler.userMessage('x',
          fallback: 'id-1', stackTrace: null));
      await call(() => f58.ErrorHandler.userMessageFor('x', fallback: 'id-1'));
      await call(() => f58.ErrorHandler.getErrorMessage(null));
    });
  });
  test('JobDisplayUtils (core/utils/job_display_utils.dart)', () async {
    await forEachScenario(() async {
      await call(() =>
          f60.JobDisplayUtils.title(f61.JobModel.fromMap(sampleJobModel)));
      await call(() =>
          f60.JobDisplayUtils.priceLine(f61.JobModel.fromMap(sampleJobModel)));
      await call(() => f60.JobDisplayUtils.offeredAmountLabel(
          f61.JobModel.fromMap(sampleJobModel)));
      await call(() =>
          f60.JobDisplayUtils.dateLine(f61.JobModel.fromMap(sampleJobModel)));
    });
  });
  test('JobStatusCopy (core/utils/job_status_copy.dart)', () async {
    await forEachScenario(() async {
      await call(() => f63.JobStatusCopy.isKnown('id-1'));
      await call(() => f63.JobStatusCopy.label('id-1'));
      await call(() => f63.JobStatusCopy.chipLabel('id-1'));
      await call(() => f63.JobStatusCopy.icon('id-1'));
      await call(() => f63.JobStatusCopy.color('id-1'));
    });
  });
  test('LocationUtils (core/utils/location_utils.dart)', () async {
    await forEachScenario(() async {
      probe(() => f64.LocationUtils());
      await call(() => f64.LocationUtils.getApproximateAddress(1.0, 1.0));
      await call(() => f64.LocationUtils.isCoordinateLikeAddress('id-1'));
      await call(() => f64.LocationUtils.resolveExactAddress(
          address: 'id-1', latitude: 1.0, longitude: 1.0));
      await call(() => f64.LocationUtils.getLocationTextForJob(
          address: 'id-1', status: 'id-1', latitude: 1.0, longitude: 1.0));
    });
  });
  test('MemoCache (core/utils/memo_cache.dart)', () async {
    await forEachScenario(() async {
      final dynamic o =
          probe(() => f65.MemoCache(ttl: const Duration(milliseconds: 1)));
      if (o != null) {
        await call(() => o.invalidate('id-1'));
        await call(() => o.clear());
      }
    });
  });
  test('MockReservedSlots (core/utils/mock_reserved_slots.dart)', () async {
    await forEachScenario(() async {
      await call(() => f66.MockReservedSlots.isReservedLabel('id-1'));
      await call(() =>
          f66.MockReservedSlots.format(const TimeOfDay(hour: 10, minute: 0)));
      await call(() => f66.MockReservedSlots.isReserved(
          const TimeOfDay(hour: 10, minute: 0)));
      await call(() => f66.MockReservedSlots.parse('id-1'));
    });
  });
  test('OpenQuoteUtils (core/utils/open_quote_utils.dart)', () async {
    await forEachScenario(() async {
      await call(() => f67.OpenQuoteUtils.invitedWorkerId(
          f61.JobModel.fromMap(sampleJobModel)));
      await call(() => f67.OpenQuoteUtils.canWorkerSubmitQuote(
          f61.JobModel.fromMap(sampleJobModel),
          '00000000-0000-4000-8000-0000000000aa'));
    });
  });
  test('AppPlatform (core/utils/platform_support.dart)', () async {
    await forEachScenario(() async {
      await call(() => f68.AppPlatform.isWeb);
      await call(() => f68.AppPlatform.isMobileNative);
      await call(() => f68.AppPlatform.isAndroid);
      await call(() => f68.AppPlatform.isIOS);
      await call(() => f68.AppPlatform.isDesktopNative);
    });
  });
  test('PortfolioMediaResolver (core/utils/portfolio_media_resolver.dart)',
      () async {
    await forEachScenario(() async {
      await call(() => f69.PortfolioMediaResolver.isVideo('id-1'));
      await call(() => f69.PortfolioMediaResolver.resolvePath('id-1'));
      await call(
          () => f69.PortfolioMediaResolver.thumbnailPath('id-1', 'id-1'));
      await call(() => f69.PortfolioMediaResolver.playbackPath('id-1', 'id-1'));
      await call(() => f69.PortfolioMediaResolver.isNetwork('id-1'));
      await call(() => f69.PortfolioMediaResolver.isAsset('id-1'));
      await call(() => f69.PortfolioMediaResolver.isLocalFile('id-1'));
    });
  });
  test('SantiagoTime (core/utils/santiago_time.dart)', () async {
    await forEachScenario(() async {
      await call(() => f70.SantiagoTime.location);
      await call(() => f70.SantiagoTime.ensureInitialized());
      await call(() => f70.SantiagoTime.wall(DateTime.utc(2026, 1, 2, 15)));
      await call(() => f70.SantiagoTime.day(DateTime.utc(2026, 1, 2, 15)));
    });
  });
  test('ServiceWorkerMapper (core/utils/service_worker_mapper.dart)', () async {
    await forEachScenario(() async {
      await call(() => f71.ServiceWorkerMapper.registrationProfessions);
      await call(() => f71.ServiceWorkerMapper.labelForCategory('id-1'));
      await call(() => f71.ServiceWorkerMapper.categoryForProfession('id-1'));
      await call(() => f71.ServiceWorkerMapper.professionForCategory('id-1'));
    });
  });
  test('Validators (core/utils/validators.dart)', () async {
    await forEachScenario(() async {
      probe(() => f72.Validators());
      await call(() => f72.Validators.validateEmail('id-1'));
      await call(() => f72.Validators.validateName('id-1'));
      await call(() => f72.Validators.validatePassword('valor-de-prueba'));
      await call(() => f72.Validators.validateSecurePassword('valor-de-prueba'));
      await call(() => f72.Validators.passwordStrength('valor-de-prueba'));
      await call(() => f72.Validators.validateRequired('id-1', 'id-1'));
      await call(() => f72.Validators.validateAddress('id-1'));
      await call(() => f72.Validators.validateDescription('id-1'));
    });
  });
  test('WorkerJobStatus (core/utils/worker_job_status.dart)', () async {
    await forEachScenario(() async {
      await call(() => f73.WorkerJobStatus.busyStatuses);
      await call(() => f73.WorkerJobStatus.isActive('id-1'));
      await call(() => f73.WorkerJobStatus.pickHighlightJob(
          [f61.JobModel.fromMap(sampleJobModel)]));
      await call(() => f73.WorkerJobStatus.activeBannerTitle('id-1'));
    });
  });
  test('WorkerZoneMatcher (core/utils/worker_zone_matcher.dart)', () async {
    await forEachScenario(() async {
      await call(() => f74.WorkerZoneMatcher.serves(
          workZone: 'id-1',
          userLocation: f24.UserLocationContext(city: 'id-1')));
    });
  });
  test(
      'JobDetailHelpers (features/jobs/presentation/utils/job_detail_helpers.dart)',
      () async {
    await forEachScenario(() async {
      await call(() => f76.JobDetailHelpers.quoteFromJob(
          f61.JobModel.fromMap(sampleJobModel)));
      await call(() => f76.JobDetailHelpers.quoteFromMetadata(
          <String, dynamic>{'id': 'id-1'}, 'id-1'));
      await call(() => f76.JobDetailHelpers.isWorkerTierInvitation(
          f61.JobModel.fromMap(sampleJobModel)));
      await call(() => f76.JobDetailHelpers.completionTargetStatus(
          f61.JobModel.fromMap(sampleJobModel)));
      await call(() => f76.JobDetailHelpers.canOpenChat('id-1'));
      await call(() => f76.JobDetailHelpers.isJobClosed('id-1'));
      await call(() => f76.JobDetailHelpers.isDisputeOpen(
          f77.DisputeModel.fromMap(sampleDisputeModel)));
      await call(() => f76.JobDetailHelpers.canOpenDispute(
          f61.JobModel.fromMap(sampleJobModel),
          f77.DisputeModel.fromMap(sampleDisputeModel)));
      await call(() => f76.JobDetailHelpers.canNegotiateDispute(
          f61.JobModel.fromMap(sampleJobModel),
          f77.DisputeModel.fromMap(sampleDisputeModel)));
      await call(() => f76.JobDetailHelpers.clientCanCancelRequest(
          job: f61.JobModel.fromMap(sampleJobModel),
          dispute: f77.DisputeModel.fromMap(sampleDisputeModel),
          userId: '00000000-0000-4000-8000-0000000000aa'));
      await call(() => f76.JobDetailHelpers.agreementTypeLabel('id-1'));
      await call(() => f76.JobDetailHelpers.statusColor('id-1'));
      await call(() => f76.JobDetailHelpers.paymentStatusLabel('id-1'));
      await call(() => f76.JobDetailHelpers.statusIcon('id-1'));
      await call(() => f76.JobDetailHelpers.statusText('id-1'));
    });
  });
  test(
      'WorkerHomeRefreshState (features/worker/presentation/providers/worker_home_refresh_provider.dart)',
      () async {
    await forEachScenario(() async {
      final dynamic o = probe(() => f81.WorkerHomeRefreshState(token: 1));
      if (o != null) {
        await call(() =>
            o.copyWith(token: 1, openTabIndex: 1, clearOpenTabIndex: true));
      }
    });
  });
  test('ContentFilter (utils/content_filter.dart)', () async {
    await forEachScenario(() async {
      await call(() => f82.ContentFilter.hasSensitiveData('id-1'));
    });
  });
}
