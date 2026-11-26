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
import 'package:myworksapp/features/jobs/presentation/pages/evidence_shutter_camera_page.dart'
    as f0;
import 'package:myworksapp/features/jobs/presentation/pages/job_detail_page.dart'
    as f1;
import 'package:myworksapp/features/jobs/presentation/pages/job_history_page.dart'
    as f2;
import 'package:myworksapp/features/jobs/presentation/pages/job_photos_page.dart'
    as f3;
import 'package:myworksapp/features/jobs/presentation/pages/job_schedule_page.dart'
    as f4;
import 'package:myworksapp/features/jobs/presentation/widgets/change_orders_section.dart'
    as f5;
import 'package:myworksapp/core/database/models/change_order_model.dart' as f6;
import 'package:myworksapp/features/jobs/presentation/widgets/client_live_tracking.dart'
    as f7;
import 'package:myworksapp/features/jobs/presentation/widgets/client_start_pin_card.dart'
    as f8;
import 'package:myworksapp/features/jobs/presentation/widgets/dispute_section.dart'
    as f9;
import 'package:myworksapp/core/database/models/dispute_model.dart' as f10;
import 'package:myworksapp/features/jobs/presentation/widgets/evidence_shutter_button.dart'
    as f11;
import 'package:myworksapp/features/jobs/presentation/widgets/job_accepted_location_card.dart'
    as f12;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_actions_section.dart'
    as f13;
import 'package:myworksapp/core/database/models/job_model.dart' as f14;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_client_approval_card.dart'
    as f15;
import 'package:myworksapp/core/domain/price_quote.dart' as f16;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_description_section.dart'
    as f17;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart'
    as f18;
import 'package:myworksapp/core/database/models/quote_proposal_model.dart'
    as f19;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_scheduled_date_row.dart'
    as f20;
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_status_header.dart'
    as f21;
import 'package:myworksapp/features/jobs/presentation/widgets/job_history_cards.dart'
    as f22;
import 'package:myworksapp/features/jobs/presentation/widgets/job_location_preview_section.dart'
    as f23;
import 'package:myworksapp/features/jobs/presentation/widgets/job_status_timeline.dart'
    as f24;
import 'package:myworksapp/features/jobs/presentation/widgets/open_quote_status_banner.dart'
    as f25;
import 'package:myworksapp/features/jobs/presentation/widgets/quote_proposals_section.dart'
    as f26;
import 'package:myworksapp/features/jobs/presentation/widgets/reschedule_section.dart'
    as f27;
import 'package:myworksapp/core/database/repositories/reschedule_repository.dart'
    as f28;
import 'package:myworksapp/core/database/repositories/worker_repository.dart'
    as f29;
import 'package:myworksapp/features/jobs/presentation/widgets/worker_gps_publisher.dart'
    as f30;
import 'package:myworksapp/features/jobs/presentation/widgets/worker_quote_form_dialog.dart'
    as f31;
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void main() {
  testWidgets(
      'EvidenceShutterCameraPage estado pendiente rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado pendiente rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado aceptado rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado aceptado rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado en_camino rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado en_camino rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado en_curso rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado en_curso rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado completado rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado completado rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado cancelado rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado cancelado rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado expirado rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado expirado rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado no_asistio rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado no_asistio rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado esperando_pago rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado esperando_pago rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador', overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado esperando_cotizaciones rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado esperando_cotizaciones rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado cotizacion_seleccionada rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado cotizacion_seleccionada rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado pausado_orden_cambio rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario', overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado pausado_orden_cambio rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'EvidenceShutterCameraPage estado esperando_aprobacion_cliente rol trabajador (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'EvidenceShutterCameraPage completo (features/jobs/presentation/pages/evidence_shutter_camera_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f0.EvidenceShutterCameraPage(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'JobDetailPage estado pendiente rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobDetailPage estado pendiente rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobDetailPage estado aceptado rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobDetailPage estado aceptado rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobDetailPage estado en_camino rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobDetailPage estado en_camino rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobDetailPage estado en_curso rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobDetailPage estado en_curso rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobDetailPage estado completado rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobDetailPage estado completado rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobDetailPage estado cancelado rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobDetailPage estado cancelado rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobDetailPage estado expirado rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobDetailPage estado expirado rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobDetailPage estado no_asistio rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobDetailPage estado no_asistio rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobDetailPage estado esperando_pago rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobDetailPage estado esperando_pago rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador', overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobDetailPage estado esperando_cotizaciones rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobDetailPage estado esperando_cotizaciones rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobDetailPage estado cotizacion_seleccionada rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobDetailPage estado cotizacion_seleccionada rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobDetailPage estado pausado_orden_cambio rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario', overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobDetailPage estado pausado_orden_cambio rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobDetailPage estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobDetailPage estado esperando_aprobacion_cliente rol trabajador (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobDetailPage completo (features/jobs/presentation/pages/job_detail_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f1.JobDetailPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'JobHistoryPage estado pendiente rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobHistoryPage estado pendiente rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobHistoryPage estado aceptado rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobHistoryPage estado aceptado rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobHistoryPage estado en_camino rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobHistoryPage estado en_camino rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobHistoryPage estado en_curso rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobHistoryPage estado en_curso rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobHistoryPage estado completado rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobHistoryPage estado completado rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobHistoryPage estado cancelado rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobHistoryPage estado cancelado rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobHistoryPage estado expirado rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobHistoryPage estado expirado rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobHistoryPage estado no_asistio rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobHistoryPage estado no_asistio rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobHistoryPage estado esperando_pago rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobHistoryPage estado esperando_pago rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador', overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobHistoryPage estado esperando_cotizaciones rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobHistoryPage estado esperando_cotizaciones rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobHistoryPage estado cotizacion_seleccionada rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobHistoryPage estado cotizacion_seleccionada rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobHistoryPage estado pausado_orden_cambio rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario', overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobHistoryPage estado pausado_orden_cambio rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobHistoryPage estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobHistoryPage estado esperando_aprobacion_cliente rol trabajador (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobHistoryPage completo (features/jobs/presentation/pages/job_history_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f2.JobHistoryPage(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'JobPhotosPage estado pendiente rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobPhotosPage estado pendiente rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobPhotosPage estado aceptado rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobPhotosPage estado aceptado rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobPhotosPage estado en_camino rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobPhotosPage estado en_camino rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobPhotosPage estado en_curso rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobPhotosPage estado en_curso rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobPhotosPage estado completado rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobPhotosPage estado completado rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobPhotosPage estado cancelado rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobPhotosPage estado cancelado rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobPhotosPage estado expirado rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobPhotosPage estado expirado rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobPhotosPage estado no_asistio rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobPhotosPage estado no_asistio rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobPhotosPage estado esperando_pago rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobPhotosPage estado esperando_pago rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobPhotosPage estado esperando_cotizaciones rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobPhotosPage estado esperando_cotizaciones rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobPhotosPage estado cotizacion_seleccionada rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobPhotosPage estado cotizacion_seleccionada rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobPhotosPage estado pausado_orden_cambio rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobPhotosPage estado pausado_orden_cambio rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobPhotosPage estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobPhotosPage estado esperando_aprobacion_cliente rol trabajador (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobPhotosPage completo (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f3.JobPhotosPage(
            jobId: '00000000-0000-4000-8000-0000000000aa', canAddPhotos: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobPhotosPage mínimo (features/jobs/presentation/pages/job_photos_page.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f3.JobPhotosPage(jobId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'JobSchedulePage estado pendiente rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobSchedulePage estado pendiente rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobSchedulePage estado aceptado rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobSchedulePage estado aceptado rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobSchedulePage estado en_camino rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobSchedulePage estado en_camino rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobSchedulePage estado en_curso rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobSchedulePage estado en_curso rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobSchedulePage estado completado rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobSchedulePage estado completado rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobSchedulePage estado cancelado rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobSchedulePage estado cancelado rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobSchedulePage estado expirado rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobSchedulePage estado expirado rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobSchedulePage estado no_asistio rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobSchedulePage estado no_asistio rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobSchedulePage estado esperando_pago rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobSchedulePage estado esperando_pago rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador', overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobSchedulePage estado esperando_cotizaciones rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobSchedulePage estado esperando_cotizaciones rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobSchedulePage estado cotizacion_seleccionada rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobSchedulePage estado cotizacion_seleccionada rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobSchedulePage estado pausado_orden_cambio rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario', overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobSchedulePage estado pausado_orden_cambio rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobSchedulePage estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobSchedulePage estado esperando_aprobacion_cliente rol trabajador (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        role: 'trabajador',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobSchedulePage completo (features/jobs/presentation/pages/job_schedule_page.dart)',
      (tester) async {
    await smokeWidget(tester, () => f4.JobSchedulePage(),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'ChangeOrdersSection completo (features/jobs/presentation/widgets/change_orders_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f5.ChangeOrdersSection(
            orders: [f6.ChangeOrderModel.fromMap(sampleChangeOrderModel)],
            isWorker: true,
            onReview: (_) {},
            onRequest: () {},
            canRequest: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ChangeOrdersSection mínimo (features/jobs/presentation/widgets/change_orders_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f5.ChangeOrdersSection(
            orders: [f6.ChangeOrderModel.fromMap(sampleChangeOrderModel)],
            isWorker: true),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'ClientLiveTracking completo (features/jobs/presentation/widgets/client_live_tracking.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f7.ClientLiveTracking(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            jobStatus: 'id-1',
            destinationLat: 1.0,
            destinationLng: 1.0),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'ClientLiveTracking mínimo (features/jobs/presentation/widgets/client_live_tracking.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f7.ClientLiveTracking(
            jobId: '00000000-0000-4000-8000-0000000000aa', jobStatus: 'id-1'),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'ClientStartPinCard completo (features/jobs/presentation/widgets/client_start_pin_card.dart)',
      (tester) async {
    await smokeWidget(tester, () => f8.ClientStartPinCard(pin: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'DisputeSection completo (features/jobs/presentation/widgets/dispute_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f9.DisputeSection(
            dispute: f10.DisputeModel.fromMap(sampleDisputeModel),
            canOpenDispute: true,
            isParticipant: true,
            canNegotiate: true,
            onOpenDispute: null,
            onAddComment: (_) async {},
            onAppeal: (_) async {},
            onRespondAgreement: (_) async {},
            onCancelRequest: () {},
            pendingAgreementType: 'id-1',
            pendingAgreementId: '00000000-0000-4000-8000-0000000000aa'),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'DisputeSection mínimo (features/jobs/presentation/widgets/dispute_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f9.DisputeSection(
            dispute: f10.DisputeModel.fromMap(sampleDisputeModel),
            canOpenDispute: true,
            isParticipant: true),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'EvidenceShutterButton completo (features/jobs/presentation/widgets/evidence_shutter_button.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.EvidenceShutterButton(
            onPhoto: () {},
            onVideoStart: () {},
            onVideoEnd: () {},
            isRecording: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'EvidenceShutterButton mínimo (features/jobs/presentation/widgets/evidence_shutter_button.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f11.EvidenceShutterButton(
            onPhoto: () {}, onVideoStart: () {}, onVideoEnd: () {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'JobAcceptedLocationCard completo (features/jobs/presentation/widgets/job_accepted_location_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f12.JobAcceptedLocationCard(
            address: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            scheduledDate: DateTime.utc(2026, 1, 2, 15),
            isLoadingAddress: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobAcceptedLocationCard mínimo (features/jobs/presentation/widgets/job_accepted_location_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f12.JobAcceptedLocationCard(
            address: 'id-1', latitude: 1.0, longitude: 1.0),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'JobDetailActionsSection estado pendiente rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pendiente'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobDetailActionsSection estado aceptado rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'aceptado'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobDetailActionsSection estado en_camino rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'en_camino'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobDetailActionsSection estado en_curso rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'en_curso'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobDetailActionsSection estado completado rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'completado'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobDetailActionsSection estado cancelado rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cancelado'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobDetailActionsSection estado expirado rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'expirado'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobDetailActionsSection estado no_asistio rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'no_asistio'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobDetailActionsSection estado esperando_pago rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_pago'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobDetailActionsSection estado esperando_cotizaciones rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_cotizaciones'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobDetailActionsSection estado cotizacion_seleccionada rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cotizacion_seleccionada'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobDetailActionsSection estado pausado_orden_cambio rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pausado_orden_cambio'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobDetailActionsSection estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_aprobacion_cliente'}),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobDetailActionsSection completo (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(sampleJobModel),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {},
            workPausedByDispute: true,
            ratingBlockedByDispute: true,
            alreadyRated: true,
            onRatingChanged: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobDetailActionsSection mínimo (features/jobs/presentation/widgets/job_detail_actions_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f13.JobDetailActionsSection(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            job: f14.JobModel.fromMap(sampleJobModel),
            isWorker: true,
            isOwner: true,
            canTransition: const {},
            onGoToDashboard: () {},
            onCancelJob: () async {},
            onAcceptJob: () {},
            onRejectJob: () async {},
            onMarkEnRoute: () {},
            onStartJob: () {},
            onRequestOvertimeHours: () {},
            onCompleteJob: () {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'JobDetailClientApprovalCard completo (features/jobs/presentation/widgets/job_detail_client_approval_card.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f15.JobDetailClientApprovalCard(
            jobId: '00000000-0000-4000-8000-0000000000aa',
            quote: f16.PriceQuote.fromJson(samplePriceQuote),
            onApprove: () {},
            onReject: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobDetailDescriptionSection estado pendiente rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pendiente'})),
        role: 'usuario',
        overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado aceptado rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'aceptado'})),
        role: 'usuario',
        overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado en_camino rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'en_camino'})),
        role: 'usuario',
        overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado en_curso rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'en_curso'})),
        role: 'usuario',
        overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado completado rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'completado'})),
        role: 'usuario',
        overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado cancelado rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cancelado'})),
        role: 'usuario',
        overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado expirado rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'expirado'})),
        role: 'usuario',
        overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado no_asistio rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'no_asistio'})),
        role: 'usuario',
        overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado esperando_pago rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_pago'})),
        role: 'usuario',
        overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado esperando_cotizaciones rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_cotizaciones'})),
        role: 'usuario',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado cotizacion_seleccionada rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cotizacion_seleccionada'})),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado pausado_orden_cambio rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pausado_orden_cambio'})),
        role: 'usuario',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobDetailDescriptionSection estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_aprobacion_cliente'})),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobDetailDescriptionSection completo (features/jobs/presentation/widgets/job_detail_description_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f17.JobDetailDescriptionSection(
            job: f14.JobModel.fromMap(sampleJobModel)),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado pendiente rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pendiente'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado aceptado rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'aceptado'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado en_camino rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'en_camino'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado en_curso rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'en_curso'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado completado rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'completado'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado cancelado rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cancelado'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado expirado rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'expirado'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado no_asistio rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'no_asistio'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado esperando_pago rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_pago'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado esperando_cotizaciones rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_cotizaciones'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado cotizacion_seleccionada rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cotizacion_seleccionada'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado pausado_orden_cambio rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pausado_orden_cambio'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_aprobacion_cliente'}),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobDetailPaymentEscrowSection completo (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(sampleJobModel),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {},
            blockedByDispute: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobDetailPaymentEscrowSection mínimo (features/jobs/presentation/widgets/job_detail_payment_escrow_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f18.JobDetailPaymentEscrowSection(
            job: f14.JobModel.fromMap(sampleJobModel),
            jobId: '00000000-0000-4000-8000-0000000000aa',
            isWorker: true,
            isClientOwner: true,
            isAssignedWorker: true,
            invitedWorkerName: 'id-1',
            quoteProposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ],
            onPayEscrow: () {},
            onApproveCompletion: () {},
            onRejectCompletion: () {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'JobDetailScheduledDateRow completo (features/jobs/presentation/widgets/job_detail_scheduled_date_row.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f20.JobDetailScheduledDateRow(
            scheduledDate: DateTime.utc(2026, 1, 2, 15)),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobDetailStatusHeader estado pendiente rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pendiente'})),
        role: 'usuario',
        overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'JobDetailStatusHeader estado aceptado rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'aceptado'})),
        role: 'usuario',
        overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'JobDetailStatusHeader estado en_camino rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'en_camino'})),
        role: 'usuario',
        overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'JobDetailStatusHeader estado en_curso rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'en_curso'})),
        role: 'usuario',
        overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'JobDetailStatusHeader estado completado rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'completado'})),
        role: 'usuario',
        overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'JobDetailStatusHeader estado cancelado rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cancelado'})),
        role: 'usuario',
        overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'JobDetailStatusHeader estado expirado rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'expirado'})),
        role: 'usuario',
        overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'JobDetailStatusHeader estado no_asistio rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'no_asistio'})),
        role: 'usuario',
        overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'JobDetailStatusHeader estado esperando_pago rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_pago'})),
        role: 'usuario',
        overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'JobDetailStatusHeader estado esperando_cotizaciones rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_cotizaciones'})),
        role: 'usuario',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'JobDetailStatusHeader estado cotizacion_seleccionada rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cotizacion_seleccionada'})),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'JobDetailStatusHeader estado pausado_orden_cambio rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pausado_orden_cambio'})),
        role: 'usuario',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'JobDetailStatusHeader estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_aprobacion_cliente'})),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'JobDetailStatusHeader completo (features/jobs/presentation/widgets/job_detail_status_header.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f21.JobDetailStatusHeader(
            job: f14.JobModel.fromMap(sampleJobModel)),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobHistoryLiveCard completo (features/jobs/presentation/widgets/job_history_cards.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.JobHistoryLiveCard(
            title: 'id-1',
            address: 'id-1',
            dateLabel: 'id-1',
            status: 'id-1',
            onTap: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobHistoryCompletedCard completo (features/jobs/presentation/widgets/job_history_cards.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.JobHistoryCompletedCard(
            title: 'id-1',
            address: 'id-1',
            dateLabel: 'id-1',
            paymentStatus: 'id-1',
            onTap: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobHistoryClosedCard completo (features/jobs/presentation/widgets/job_history_cards.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f22.JobHistoryClosedCard(
            title: 'id-1',
            address: 'id-1',
            dateLabel: 'id-1',
            status: 'id-1',
            onTap: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobLocationPreviewSection completo (features/jobs/presentation/widgets/job_location_preview_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.JobLocationPreviewSection(
            address: 'id-1',
            latitude: 1.0,
            longitude: 1.0,
            isLoadingAddress: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'JobLocationPreviewSection mínimo (features/jobs/presentation/widgets/job_location_preview_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f23.JobLocationPreviewSection(
            address: 'id-1', latitude: 1.0, longitude: 1.0),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'JobStatusTimeline completo (features/jobs/presentation/widgets/job_status_timeline.dart)',
      (tester) async {
    await smokeWidget(tester, () => f24.JobStatusTimeline(status: 'id-1'),
        seeded: true, role: 'usuario');
  });
  testWidgets(
      'OpenQuoteStatusBanner completo (features/jobs/presentation/widgets/open_quote_status_banner.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f25.OpenQuoteStatusBanner(
            jobStatus: 'id-1',
            isClient: true,
            workerName: 'id-1',
            proposalsCount: 1),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'OpenQuoteStatusBanner mínimo (features/jobs/presentation/widgets/open_quote_status_banner.dart)',
      (tester) async {
    await smokeWidget(tester,
        () => f25.OpenQuoteStatusBanner(jobStatus: 'id-1', isClient: true),
        seeded: false, role: 'usuario');
  });
  testWidgets(
      'QuoteProposalsSection completo (features/jobs/presentation/widgets/quote_proposals_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.QuoteProposalsSection(
                proposals: [
                  f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
                ],
                isClient: true,
                jobStatus: 'id-1',
                onSelect: (_) {},
                onSubmitQuote: () {}),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'QuoteProposalsSection mínimo (features/jobs/presentation/widgets/quote_proposals_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f26.QuoteProposalsSection(proposals: [
              f19.QuoteProposalModel.fromMap(sampleQuoteProposalModel)
            ], isClient: true, jobStatus: 'id-1'),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'RescheduleSection estado pendiente rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pendiente'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'pendiente'});
  });
  testWidgets(
      'RescheduleSection estado aceptado rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'aceptado'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'aceptado'});
  });
  testWidgets(
      'RescheduleSection estado en_camino rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'en_camino'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'en_camino'});
  });
  testWidgets(
      'RescheduleSection estado en_curso rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'en_curso'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'en_curso'});
  });
  testWidgets(
      'RescheduleSection estado completado rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'completado'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'completado'});
  });
  testWidgets(
      'RescheduleSection estado cancelado rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cancelado'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'cancelado'});
  });
  testWidgets(
      'RescheduleSection estado expirado rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job:
                f14.JobModel.fromMap({...sampleJobModel, 'estado': 'expirado'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'expirado'});
  });
  testWidgets(
      'RescheduleSection estado no_asistio rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'no_asistio'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'no_asistio'});
  });
  testWidgets(
      'RescheduleSection estado esperando_pago rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_pago'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'esperando_pago'});
  });
  testWidgets(
      'RescheduleSection estado esperando_cotizaciones rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_cotizaciones'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'esperando_cotizaciones'});
  });
  testWidgets(
      'RescheduleSection estado cotizacion_seleccionada rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'cotizacion_seleccionada'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'cotizacion_seleccionada'});
  });
  testWidgets(
      'RescheduleSection estado pausado_orden_cambio rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'pausado_orden_cambio'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'pausado_orden_cambio'});
  });
  testWidgets(
      'RescheduleSection estado esperando_aprobacion_cliente rol usuario (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(
                {...sampleJobModel, 'estado': 'esperando_aprobacion_cliente'}),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        role: 'usuario',
        overrides: const {'estado': 'esperando_aprobacion_cliente'});
  });
  testWidgets(
      'RescheduleSection completo (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(sampleJobModel),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {},
            repository: f28.RescheduleRepository(),
            workerRepository: f29.WorkerRepository()),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'RescheduleSection mínimo (features/jobs/presentation/widgets/reschedule_section.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f27.RescheduleSection(
            job: f14.JobModel.fromMap(sampleJobModel),
            currentUserId: '00000000-0000-4000-8000-0000000000aa',
            onChanged: () async {}),
        seeded: false,
        role: 'usuario');
  });
  testWidgets(
      'WorkerGpsPublisher completo (features/jobs/presentation/widgets/worker_gps_publisher.dart)',
      (tester) async {
    await smokeWidget(
        tester,
        () => f30.WorkerGpsPublisher(
            jobId: '00000000-0000-4000-8000-0000000000aa', active: true),
        seeded: true,
        role: 'usuario');
  });
  testWidgets(
      'WorkerQuoteFormDialog completo (features/jobs/presentation/widgets/worker_quote_form_dialog.dart)',
      (tester) async {
    await smokeWidget(tester, () => f31.WorkerQuoteFormDialog(),
        seeded: true, role: 'usuario');
  });
}
