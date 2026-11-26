// AdminJobDetailPage: pestañas con datos reales (chat, pagos, historial con
// calificación, disputa y cancelación), cancelar trabajo, resolver disputa,
// trabajo inexistente y errores de carga.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/admin/presentation/pages/admin_job_detail_page.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

const _job = '00000000-0000-4000-8000-0000000006b1';
const _pro = '00000000-0000-4000-8000-00000000e001';

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<bool> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return false;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t, 3);
  return true;
}

void _seed(FakeBackend b, {bool completo = true, String disputa = 'abierta'}) {
  b.seed('trabajos', [
    {
      ...sampleJobModel,
      'id': _job,
      'id_usuario': fakeUserId,
      'id_trabajador': _pro,
      'estado': 'en_curso',
    },
  ]);
  b.seed('perfiles', [
    {
      ...sampleUserModel,
      'id': fakeUserId,
      'nombre': 'Ana Pérez',
      'rol': 'admin'
    },
    {...sampleUserModel, 'id': _pro, 'nombre': 'Pedro Rojas'},
  ]);
  if (!completo) {
    for (final t in [
      'mensajes',
      'pagos',
      'disputas',
      'calificaciones',
      'cancelaciones_trabajo',
    ]) {
      b.seed(t, []);
    }
    return;
  }
  b.seed('mensajes', [
    for (var i = 0; i < 3; i++)
      {
        ...sampleMessageModel,
        'id': 'm$i',
        'id_trabajo': _job,
        'id_remitente': i.isEven ? fakeUserId : _pro,
        'contenido': 'Mensaje $i',
      },
  ]);
  b.seed('pagos', [
    {
      ...samplePaymentModel,
      'id': 'pg1',
      'id_trabajo': _job,
      'estado': 'liberado'
    },
    {
      ...samplePaymentModel,
      'id': 'pg2',
      'id_trabajo': _job,
      'estado': 'retenido'
    },
  ]);
  b.seed('disputas', [
    {
      ...sampleDisputeModel,
      'id': 'd1',
      'id_trabajo': _job,
      'estado': disputa,
      'descripcion': 'No terminó el trabajo',
      'resolucion': disputa == 'resuelta' ? 'Se devolvió el dinero' : null,
    },
  ]);
  b.seed('calificaciones', [
    {
      ...sampleRatingModel,
      'id': 'r1',
      'id_trabajo': _job,
      'puntaje': 4,
      'comentario': 'Buen trabajo',
    },
  ]);
  b.seed('cancelaciones_trabajo', [
    {
      'id': 'c1',
      'id_trabajo': _job,
      'cancelado_por': 'cliente',
      'motivo': 'Cambio de planes',
      'cancelado_en': '2026-03-01T12:00:00Z',
    },
  ]);
}

Future<void> _pestanas(WidgetTester t) async {
  for (final p in ['Chat', 'Pagos', 'Historial', 'Resumen']) {
    await _tap(t, find.textContaining(p));
  }
}

Future<void> _recorrido(WidgetTester t) async {
  await _pasos(t, 5);
  await _pestanas(t);
  await _tap(t, find.textContaining('Historial'));
  for (final opcion in [
    'Cancelar',
    'Devolver a la tarjeta',
    'Liberar al profesional'
  ]) {
    if (!await _tap(t, find.text('Resolver disputa'))) break;
    final campo = find.byType(TextField);
    if (campo.evaluate().isNotEmpty) {
      await t.enterText(campo.last, 'Acuerdo de prueba entre las partes');
      await t.pump();
    }
    await _tap(t, find.text(opcion).last);
    await _pasos(t, 3);
  }
  await _tap(t, find.byTooltip('Actualizar'));
  await _tap(t, find.byTooltip('Cancelar trabajo'));
  await _tap(t, find.text('No'));
  await _tap(t, find.byTooltip('Cancelar trabajo'));
  await _tap(t, find.text('Cancelar trabajo').last);
  await _pasos(t, 4);
}

void main() {
  testWidgets('detalle completo con disputa abierta', (t) async {
    await smokeWidget(t, () => const AdminJobDetailPage(jobId: _job),
        interact: false, role: 'admin', setup: _seed, script: _recorrido);
    // Regresión B8: cerrar el diálogo de resolución no usa el controlador
    // ya liberado.
    expect(smokeBugErrors(), isEmpty);
  });

  testWidgets('disputa en revisión y fallas al cancelar', (t) async {
    await smokeWidget(t, () => const AdminJobDetailPage(jobId: _job),
        interact: false, role: 'admin', setup: (b) {
      _seed(b, disputa: 'en_revision');
      b.failing.add('fn:payment-refund');
      b.failing.add('trabajos:patch');
      b.defaultFunction = (_) => {'error': 'reembolso rechazado'};
    }, script: _recorrido);
    expect(smokeBugErrors(), isEmpty);
  });

  testWidgets('detalle sin datos adicionales', (t) async {
    await smokeWidget(t, () => const AdminJobDetailPage(jobId: _job),
        interact: false,
        role: 'admin',
        setup: (b) => _seed(b, completo: false),
        script: (t) async {
          await _pasos(t, 5);
          await _pestanas(t);
        });
  });

  testWidgets('trabajo inexistente', (t) async {
    await smokeWidget(t, () => const AdminJobDetailPage(jobId: 'no-existe'),
        interact: false,
        role: 'admin',
        setup: (b) {
          b.seed('trabajos', []);
        },
        script: (t) => _pasos(t, 4));
  });

  testWidgets('error de carga', (t) async {
    await smokeWidget(t, () => const AdminJobDetailPage(jobId: _job),
        interact: false,
        role: 'admin',
        setup: (b) {
          b.failing.add('trabajos');
        },
        script: (t) => _pasos(t, 4));
  });
}
