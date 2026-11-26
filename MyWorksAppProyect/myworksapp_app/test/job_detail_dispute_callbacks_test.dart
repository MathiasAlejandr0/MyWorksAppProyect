// JobDetailPage: callbacks de la sección de disputa invocados como lo haría
// la UI: abrir disputa (con acuerdo propuesto, con acuerdo fallido y con error
// de validación), comentar, apelar y responder el acuerdo pendiente, cada uno
// con éxito y con error del backend.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/pages/job_detail_page.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/dispute_section.dart';

import 'support/fake_supabase.dart';
import 'support/job_detail_script.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

void Function(FakeBackend) _datos({
  bool conDisputa = true,
  bool falla = false,
  bool acuerdoFalla = false,
}) =>
    (b) {
      b.seed('trabajos', [
        {
          ...universalRow,
          ...sampleJobModel,
          'id': detailJobId,
          'estado': 'en_curso',
          'id_usuario': fakeUserId,
          'id_trabajador': detailOtherId,
          'metadatos_servicio': <String, dynamic>{},
          'modalidad_cobro': 'precio_fijo',
        },
      ]);
      b.seed('disputas', [
        if (conDisputa)
          {
            ...sampleDisputeModel,
            'id': 'disp-1',
            'id_trabajo': detailJobId,
            'abierta_por': fakeUserId,
            'estado': 'abierta',
            'motivo': 'calidad',
          },
      ]);
      b.rpc('acuerdo_pendiente', [
        {'id': 'acuerdo-1', 'tipo': 'reembolso_parcial'},
      ]);
      if (falla) {
        b.rpcErrors.addAll({
          'apelar_disputa': 'apelación rechazada',
          'comentar_disputa': 'comentario rechazado',
          'responder_acuerdo': 'acuerdo vencido',
        });
      }
      if (acuerdoFalla) {
        b.rpcErrors['proponer_acuerdo'] = 'sin acuerdo';
      }
    };

Future<void> _con(WidgetTester t, void Function(FakeBackend) setup,
    Future<void> Function(WidgetTester t, DisputeSection s) cuerpo) {
  return smokeWidget(t, () => const JobDetailPage(jobId: detailJobId),
      interact: false,
      boundedButtons: true,
      size: const Size(480, 3600),
      setup: setup, script: (t) async {
    await detailSteps(t, 6);
    final f = find.byType(DisputeSection);
    expect(f, findsOneWidget);
    await cuerpo(t, t.widget<DisputeSection>(f));
    await detailSteps(t, 4);
  });
}

void main() {
  for (final falla in [false, true]) {
    testWidgets('comentar, apelar y responder acuerdo (falla $falla)',
        (t) async {
      await _con(t, _datos(falla: falla), (t, s) async {
        await t.runAsync(() => s.onAddComment!('Sigue goteando'));
        await detailSteps(t, 2);
        final s2 = t.widget<DisputeSection>(find.byType(DisputeSection));
        await t.runAsync(() => s2.onAppeal!('No estoy de acuerdo'));
        await detailSteps(t, 2);
        final s3 = t.widget<DisputeSection>(find.byType(DisputeSection));
        await t.runAsync(() => s3.onRespondAgreement!(true));
        await detailSteps(t, 2);
        final s4 = t.widget<DisputeSection>(find.byType(DisputeSection));
        await t.runAsync(() => s4.onRespondAgreement!(false));
        await detailSteps(t, 2);
      });
    });
  }

  for (final acuerdoFalla in [false, true]) {
    testWidgets('abrir disputa con acuerdo propuesto (falla $acuerdoFalla)',
        (t) async {
      await _con(t, _datos(conDisputa: false, acuerdoFalla: acuerdoFalla),
          (t, s) async {
        await t.runAsync(() =>
            s.onOpenDispute!('calidad', 'Quedó mal', 'reembolso_parcial'));
        await detailSteps(t, 3);
      });
    });
  }

  testWidgets('abrir disputa cuando ya existe una (error de validación)',
      (t) async {
    await _con(t, _datos(), (t, s) async {
      await t.runAsync(() => s.onOpenDispute!('calidad', null, ''));
      await detailSteps(t, 3);
    });
  });

  testWidgets(
      'trabajo cancelado por profesional no disponible muestra alternativas',
      (t) async {
    await smokeWidget(t, () => const JobDetailPage(jobId: detailJobId),
        interact: false,
        boundedButtons: true,
        size: const Size(480, 3600), setup: (b) {
      b.seed('trabajos', [
        {
          ...universalRow,
          ...sampleJobModel,
          'id': detailJobId,
          'estado': 'cancelado',
          'id_usuario': fakeUserId,
          'id_trabajador': detailOtherId,
          'metadatos_servicio': <String, dynamic>{
            'rejection_reason': 'worker_unavailable',
            'rejected_by_worker_id': detailOtherId,
          },
          'modalidad_cobro': 'precio_fijo',
        },
      ]);
      b.seed('disputas', []);
    }, script: (t) async {
      await detailSteps(t, 8);
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
