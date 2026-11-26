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
    await smokeWidget(tester, () => f0.StatisticsPage(),
        seeded: true, role: 'trabajador');
  });
  testWidgets(
      'WorkerHomePage completo (features/worker/presentation/pages/worker_home_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f1.WorkerHomePage(),
        seeded: true, role: 'trabajador');
  });
  testWidgets(
      'WorkerPayoutsPage completo (features/worker/presentation/pages/worker_payouts_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.WorkerPayoutsPage(),
        seeded: true, role: 'trabajador');
  });
  testWidgets(
      'WorkerPricingSetupPage completo (features/worker/presentation/pages/worker_pricing_setup_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.WorkerPricingSetupPage(editMode: true),
        seeded: true, role: 'trabajador');
  });
  testWidgets(
      'WorkerPricingSetupPage mínimo (features/worker/presentation/pages/worker_pricing_setup_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f3.WorkerPricingSetupPage(),
        seeded: false, role: 'trabajador');
  });
  testWidgets(
      'WorkerProfilePage completo (features/worker/presentation/pages/worker_profile_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.WorkerProfilePage(),
        seeded: true, role: 'trabajador');
  });
  testWidgets(
      'WorkerRegisterPage completo (features/worker/presentation/pages/worker_register_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f5.WorkerRegisterPage(),
        seeded: true, role: 'trabajador');
  });
  testWidgets(
      'WorkerSchedulePage completo (features/worker/presentation/pages/worker_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f6.WorkerSchedulePage(),
        seeded: true, role: 'trabajador');
  });
  testWidgets(
      'SiiTaxInfoWidget completo (features/worker/presentation/widgets/sii_tax_info_widget.dart)',
      (tester) async {
    await smokeWidget(tester, () => f7.SiiTaxInfoWidget(),
        seeded: true, role: 'trabajador');
  });
  testWidgets(
      'WorkerActiveJobBanner estado pendiente rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job:
                f9.JobModel.fromMap({...sampleJobModel, 'estado': 'pendiente'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'pendiente',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado aceptado rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap({...sampleJobModel, 'estado': 'aceptado'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'aceptado',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado en_camino rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job:
                f9.JobModel.fromMap({...sampleJobModel, 'estado': 'en_camino'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'en_camino',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado en_curso rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap({...sampleJobModel, 'estado': 'en_curso'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'en_curso',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado completado rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'completado'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'completado',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado cancelado rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job:
                f9.JobModel.fromMap({...sampleJobModel, 'estado': 'cancelado'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'cancelado',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado expirado rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap({...sampleJobModel, 'estado': 'expirado'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'expirado',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado no_asistio rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'no_asistio'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'no_asistio',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado esperando_pago rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_pago'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'esperando_pago',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado esperando_cotizaciones rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_cotizaciones'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'esperando_cotizaciones',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado cotizacion_seleccionada rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cotizacion_seleccionada'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'cotizacion_seleccionada',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado pausado_orden_cambio rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pausado_orden_cambio'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'pausado_orden_cambio',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerActiveJobBanner estado esperando_aprobacion_cliente rol trabajador (features/worker/presentation/widgets/worker_active_job_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f8.WorkerActiveJobBanner(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_aprobacion_cliente'}),
            onTap: () {},
            onChat: () {}),
        role: 'trabajador',
        overrides: const {
          'estado': 'esperando_aprobacion_cliente',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
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
        seeded: true,
        role: 'trabajador');
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
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerCustomServicesEditor completo (features/worker/presentation/widgets/worker_custom_services_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.WorkerCustomServicesEditor(services: [
              f12.WorkerCustomService.fromMap(sampleWorkerCustomService)
            ], onChanged: (_) {}, enabled: true),
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerCustomServicesEditor mínimo (features/worker/presentation/widgets/worker_custom_services_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.WorkerCustomServicesEditor(services: [
              f12.WorkerCustomService.fromMap(sampleWorkerCustomService)
            ], onChanged: (_) {}),
        seeded: false,
        role: 'trabajador');
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
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerDemoTourOverlay completo (features/worker/presentation/widgets/worker_demo_tour_overlay.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f15.WorkerDemoTourOverlay(
            child: const SizedBox(),
            steps: [f16.GuidedTourStep(title: 'id-1', description: 'id-1')]),
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerEarningsSummary completo (features/worker/presentation/widgets/worker_earnings_summary.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.WorkerEarningsSummary(
            workerId: '00000000-0000-4000-8000-0000000000aa',
            onViewDetails: () {}),
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerEarningsSummary mínimo (features/worker/presentation/widgets/worker_earnings_summary.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.WorkerEarningsSummary(
            workerId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: false,
        role: 'trabajador');
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
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerEarningsCard mínimo (features/worker/presentation/widgets/worker_earnings_summary.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.WorkerEarningsCard(
            data: f18.WorkerEarningsSnapshot(
                escrowClp: 1, releasedClp: 1, pendingClp: 1, paymentCount: 1)),
        seeded: false,
        role: 'trabajador');
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
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerJobCard estado pendiente rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job:
                f9.JobModel.fromMap({...sampleJobModel, 'estado': 'pendiente'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'pendiente',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado aceptado rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap({...sampleJobModel, 'estado': 'aceptado'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'aceptado',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado en_camino rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job:
                f9.JobModel.fromMap({...sampleJobModel, 'estado': 'en_camino'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'en_camino',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado en_curso rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap({...sampleJobModel, 'estado': 'en_curso'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'en_curso',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado completado rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'completado'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'completado',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado cancelado rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job:
                f9.JobModel.fromMap({...sampleJobModel, 'estado': 'cancelado'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'cancelado',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado expirado rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap({...sampleJobModel, 'estado': 'expirado'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'expirado',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado no_asistio rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'no_asistio'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'no_asistio',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado esperando_pago rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_pago'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'esperando_pago',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado esperando_cotizaciones rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_cotizaciones'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'esperando_cotizaciones',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado cotizacion_seleccionada rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cotizacion_seleccionada'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'cotizacion_seleccionada',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado pausado_orden_cambio rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pausado_orden_cambio'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'pausado_orden_cambio',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
  });
  testWidgets(
      'WorkerJobCard estado esperando_aprobacion_cliente rol trabajador (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_aprobacion_cliente'}),
            onTap: () {},
            clientRatingLabel: 'id-1',
            clientName: 'id-1',
            priceLabel: 'id-1'),
        role: 'trabajador',
        overrides: const {
          'estado': 'esperando_aprobacion_cliente',
          'id_trabajador': '00000000-0000-4000-8000-000000000001'
        });
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
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerJobCard mínimo (features/worker/presentation/widgets/worker_job_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.WorkerJobCard(
            job: f9.JobModel.fromMap(sampleJobModel), onTap: () {}),
        seeded: false,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerOnboardingCard completo (features/worker/presentation/widgets/worker_onboarding_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f24.WorkerOnboardingCard(
            workerId: '00000000-0000-4000-8000-0000000000aa',
            onCompleted: () {}),
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerOnboardingCard mínimo (features/worker/presentation/widgets/worker_onboarding_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f24.WorkerOnboardingCard(
            workerId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: false,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerPricingTiersEditor completo (features/worker/presentation/widgets/worker_pricing_tiers_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f25.WorkerPricingTiersEditor(
            category: 'id-1',
            initialTiers: <String, int>{},
            onChanged: (_) {},
            enabled: true),
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerPricingTiersEditor mínimo (features/worker/presentation/widgets/worker_pricing_tiers_editor.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f25.WorkerPricingTiersEditor(
            category: 'id-1', initialTiers: <String, int>{}, onChanged: (_) {}),
        seeded: false,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerProfileSectionCard completo (features/worker/presentation/widgets/worker_profile_section_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.WorkerProfileSectionCard(
            icon: Icons.star,
            title: 'id-1',
            summary: <String>['id-1'],
            editing: true,
            onEdit: () {},
            onCancel: () {},
            onSave: () {},
            saving: true,
            child: const SizedBox(),
            alwaysShowBody: true,
            showSaveActions: true,
            saveLabel: 'id-1'),
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerProfileSectionCard mínimo (features/worker/presentation/widgets/worker_profile_section_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.WorkerProfileSectionCard(
            icon: Icons.star,
            title: 'id-1',
            summary: <String>['id-1'],
            editing: true,
            onEdit: () {}),
        seeded: false,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerQuickActionsRow completo (features/worker/presentation/widgets/worker_quick_actions_row.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.WorkerQuickActionsRow(
            onCalendar: () {}, onHistory: () {}, onEarnings: () {}),
        seeded: true,
        role: 'trabajador');
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
        seeded: true,
        role: 'trabajador');
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
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerVerificationCard completo (features/worker/presentation/widgets/worker_verification_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f30.WorkerVerificationCard(
            userId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'trabajador');
  });
  testWidgets(
      'WorkerWorkZoneField completo (features/worker/presentation/widgets/worker_work_zone_field.dart)',
      (tester) async {
    await smokeWidget(
        tester, () => f31.WorkerWorkZoneField(value: 'id-1', onChanged: (_) {}),
        seeded: true, role: 'trabajador');
  });
}
