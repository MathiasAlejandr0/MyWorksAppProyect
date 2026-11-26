// GENERADO por scripts/cobertura/gen_widgets.py. No editar a mano.
// Tests de humo de widgets: montan cada widget contra el backend falso,
// tocan sus botones y escriben en sus campos (test/support/widget_harness.dart).
// ignore_for_file: prefer_const_constructors, deprecated_member_use, unused_import
// ignore_for_file: prefer_single_quotes, avoid_dynamic_calls
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:myworksapp/features/worker/presentation/pages/statistics_page.dart'
    as f0;
import 'package:myworksapp/features/worker/presentation/pages/worker_home_page.dart'
    as f1;
import 'package:myworksapp/features/worker/presentation/pages/worker_payouts_page.dart'
    as f2;
import 'package:myworksapp/features/worker/presentation/pages/worker_pricing_setup_page.dart'
    as f3;
import 'package:myworksapp/features/worker/presentation/pages/worker_profile_page.dart'
    as f4;
import 'package:myworksapp/features/worker/presentation/pages/worker_register_page.dart'
    as f5;
import 'package:myworksapp/features/worker/presentation/pages/worker_schedule_page.dart'
    as f6;
import 'package:myworksapp/features/worker/presentation/widgets/sii_tax_info_widget.dart'
    as f7;
import 'package:myworksapp/features/worker/presentation/widgets/worker_active_job_banner.dart'
    as f8;
import 'package:myworksapp/core/database/models/job_model.dart' as f9;
import 'package:myworksapp/features/worker/presentation/widgets/worker_base_location_card.dart'
    as f10;
import 'package:myworksapp/features/worker/presentation/widgets/worker_custom_services_editor.dart'
    as f11;
import 'package:myworksapp/core/domain/worker_custom_service.dart' as f12;
import 'package:myworksapp/features/worker/presentation/widgets/worker_day_windows_editor.dart'
    as f13;
import 'package:myworksapp/core/domain/weekly_schedule.dart' as f14;
import 'package:myworksapp/features/worker/presentation/widgets/worker_demo_tour_overlay.dart'
    as f15;
import 'package:myworksapp/core/widgets/app_guided_tour.dart' as f16;
import 'package:myworksapp/features/worker/presentation/widgets/worker_earnings_summary.dart'
    as f17;
import 'package:myworksapp/core/domain/worker_earnings_snapshot.dart' as f18;
import 'package:myworksapp/features/worker/presentation/widgets/worker_header.dart'
    as f19;
import 'package:myworksapp/core/database/models/worker_model.dart' as f20;
import 'package:myworksapp/features/worker/presentation/widgets/worker_hours_editor.dart'
    as f21;
import 'package:myworksapp/core/domain/worker_hours.dart' as f22;
import 'package:myworksapp/features/worker/presentation/widgets/worker_job_card.dart'
    as f23;
import 'package:myworksapp/features/worker/presentation/widgets/worker_onboarding_card.dart'
    as f24;
import 'package:myworksapp/features/worker/presentation/widgets/worker_pricing_tiers_editor.dart'
    as f25;
import 'package:myworksapp/features/worker/presentation/widgets/worker_profile_section_card.dart'
    as f26;
import 'package:myworksapp/features/worker/presentation/widgets/worker_quick_actions_row.dart'
    as f27;
import 'package:myworksapp/features/worker/presentation/widgets/worker_stats_row.dart'
    as f28;
import 'package:myworksapp/features/worker/presentation/widgets/worker_urban_coverage_card.dart'
    as f29;
import 'package:myworksapp/features/worker/presentation/widgets/worker_verification_card.dart'
    as f30;
import 'package:myworksapp/features/worker/presentation/widgets/worker_work_zone_field.dart'
    as f31;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'StatisticsPage completo (features/worker/presentation/pages/statistics_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.StatisticsPage(), seeded: true);
  });
  testWidgets(
      'WorkerHomePage completo (features/worker/presentation/pages/worker_home_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.WorkerHomePage(), seeded: true);
  });
  testWidgets(
      'WorkerPayoutsPage completo (features/worker/presentation/pages/worker_payouts_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.WorkerPayoutsPage(), seeded: true);
  });
  testWidgets(
      'WorkerPricingSetupPage completo (features/worker/presentation/pages/worker_pricing_setup_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.WorkerPricingSetupPage(editMode: true),
        seeded: true);
  });
  testWidgets(
      'WorkerPricingSetupPage mínimo (features/worker/presentation/pages/worker_pricing_setup_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.WorkerPricingSetupPage(), seeded: false);
  });
  testWidgets(
      'WorkerProfilePage completo (features/worker/presentation/pages/worker_profile_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.WorkerProfilePage(), seeded: true);
  });
  testWidgets(
      'WorkerRegisterPage completo (features/worker/presentation/pages/worker_register_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f5.WorkerRegisterPage(), seeded: true);
  });
  testWidgets(
      'WorkerSchedulePage completo (features/worker/presentation/pages/worker_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f6.WorkerSchedulePage(), seeded: true);
  });
  testWidgets(
      'SiiTaxInfoWidget completo (features/worker/presentation/widgets/sii_tax_info_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f7.SiiTaxInfoWidget(), seeded: true);
  });
  testWidgets(
      'WorkerActiveJobBanner completo (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap(sampleJobModel),
            onTap: () {},
            onChat: () {}),
        seeded: true);
  });
  testWidgets(
      'WorkerBaseLocationCard completo (features/worker/presentation/widgets/worker_base_location_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f10.WorkerBaseLocationCard(
            latitude: 1.0,
            longitude: 1.0,
            radiusKm: 1.0,
            origin: 'id-1',
            enabled: true,
            onSave: (_, __, ___) async {}),
        seeded: true);
  });
  testWidgets(
      'WorkerCustomServicesEditor completo (features/worker/presentation/widgets/worker_custom_services_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.WorkerCustomServicesEditor(services: [
              f12.WorkerCustomService.fromMap(sampleWorkerCustomService)
            ], onChanged: (_) {}, enabled: true),
        seeded: true);
  });
  testWidgets(
      'WorkerCustomServicesEditor mínimo (features/worker/presentation/widgets/worker_custom_services_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.WorkerCustomServicesEditor(services: [
              f12.WorkerCustomService.fromMap(sampleWorkerCustomService)
            ], onChanged: (_) {}),
        seeded: false);
  });
  testWidgets(
      'WorkerDayWindowsEditor completo (features/worker/presentation/widgets/worker_day_windows_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.WorkerDayWindowsEditor(
            name: 'id-1',
            day: f14.DayWindow(weekday: 1, startMinute: 1, endMinute: 1),
            onChanged: (_) {}),
        seeded: true);
  });
  testWidgets(
      'WorkerDemoTourOverlay completo (features/worker/presentation/widgets/worker_demo_tour_overlay.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f15.WorkerDemoTourOverlay(
            child: const SizedBox(),
            steps: [f16.GuidedTourStep(title: 'id-1', description: 'id-1')]),
        seeded: true);
  });
  testWidgets(
      'WorkerEarningsSummary completo (features/worker/presentation/widgets/worker_earnings_summary.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f17.WorkerEarningsSummary(workerId: 'id-1', onViewDetails: () {}),
        seeded: true);
  });
  testWidgets(
      'WorkerEarningsSummary mínimo (features/worker/presentation/widgets/worker_earnings_summary.dart)',
      (tester) async {
    await smokeWidget(tester, () => f17.WorkerEarningsSummary(workerId: 'id-1'),
        seeded: false);
  });
  testWidgets(
      'WorkerEarningsCard completo (features/worker/presentation/widgets/worker_earnings_summary.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.WorkerEarningsCard(
            data: f18.WorkerEarningsSnapshot(
                escrowClp: 1, releasedClp: 1, pendingClp: 1, paymentCount: 1),
            onViewDetails: () {}),
        seeded: true);
  });
  testWidgets(
      'WorkerEarningsCard mínimo (features/worker/presentation/widgets/worker_earnings_summary.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.WorkerEarningsCard(
            data: f18.WorkerEarningsSnapshot(
                escrowClp: 1, releasedClp: 1, pendingClp: 1, paymentCount: 1)),
        seeded: false);
  });
  testWidgets(
      'WorkerHoursEditor completo (features/worker/presentation/widgets/worker_hours_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.WorkerHoursEditor(
            hours: [f22.WorkerHourSlot(weekday: 1, time: 'id-1')],
            selectedWeekday: 1,
            onSelectWeekday: (_) {},
            onAddHour: (_) async {},
            onRemoveHour: (_) {},
            saving: true),
        seeded: true);
  });
  testWidgets(
      'WorkerJobCard completo (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(sampleJobModel),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'WorkerJobCard mínimo (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(sampleJobModel), onTap: () {}),
        seeded: false);
  });
  testWidgets(
      'WorkerOnboardingCard completo (features/worker/presentation/widgets/worker_onboarding_card.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f24.WorkerOnboardingCard(workerId: 'id-1', onCompleted: () {}),
        seeded: true);
  });
  testWidgets(
      'WorkerOnboardingCard mínimo (features/worker/presentation/widgets/worker_onboarding_card.dart)',
      (tester) async {
    await smokeWidget(tester, () => f24.WorkerOnboardingCard(workerId: 'id-1'),
        seeded: false);
  });
  testWidgets(
      'WorkerPricingTiersEditor completo (features/worker/presentation/widgets/worker_pricing_tiers_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f25.WorkerPricingTiersEditor(
            category: 'id-1',
            initialTiers: const {},
            onChanged: (_) {},
            enabled: true),
        seeded: true);
  });
  testWidgets(
      'WorkerPricingTiersEditor mínimo (features/worker/presentation/widgets/worker_pricing_tiers_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f25.WorkerPricingTiersEditor(
            category: 'id-1', initialTiers: const {}, onChanged: (_) {}),
        seeded: false);
  });
  testWidgets(
      'WorkerProfileSectionCard completo (features/worker/presentation/widgets/worker_profile_section_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.WorkerProfileSectionCard(
            icon: Icons.star,
            title: 'id-1',
            summary: ['id-1'],
            editing: true,
            onEdit: () {},
            onCancel: () {},
            onSave: () {},
            saving: true,
            child: const SizedBox(),
            alwaysShowBody: true,
            showSaveActions: true,
            saveLabel: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'WorkerProfileSectionCard mínimo (features/worker/presentation/widgets/worker_profile_section_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.WorkerProfileSectionCard(
            icon: Icons.star,
            title: 'id-1',
            summary: ['id-1'],
            editing: true,
            onEdit: () {}),
        seeded: false);
  });
  testWidgets(
      'WorkerQuickActionsRow completo (features/worker/presentation/widgets/worker_quick_actions_row.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.WorkerQuickActionsRow(
            onCalendar: () {}, onHistory: () {}, onEarnings: () {}),
        seeded: true);
  });
  testWidgets(
      'WorkerStatsRow completo (features/worker/presentation/widgets/worker_stats_row.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f28.WorkerStatsRow(
            pending: 1,
            active: 1,
            completed: 1,
            selectedIndex: 1,
            onTap: (_) {}),
        seeded: true);
  });
  testWidgets(
      'WorkerUrbanCoverageCard completo (features/worker/presentation/widgets/worker_urban_coverage_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f29.WorkerUrbanCoverageCard(
            urbanRadiusKm: 1.0,
            outsideFeeClp: 1,
            enabled: true,
            onSave: (_, __) async {}),
        seeded: true);
  });
  testWidgets(
      'WorkerVerificationCard completo (features/worker/presentation/widgets/worker_verification_card.dart)',
      (tester) async {
    await smokeWidget(tester, () => f30.WorkerVerificationCard(userId: 'id-1'),
        seeded: true);
  });
  testWidgets(
      'WorkerWorkZoneField completo (features/worker/presentation/widgets/worker_work_zone_field.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f31.WorkerWorkZoneField(value: 'id-1', onChanged: (_) {}),
        seeded: true);
  });
}
