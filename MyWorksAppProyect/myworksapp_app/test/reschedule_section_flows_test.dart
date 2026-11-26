// RescheduleSection: proponer otra hora (con y sin horas libres), aceptar,
// rechazar o retirar una propuesta pendiente, historial y errores del RPC.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/reschedule_section.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

const _pro = 'pro-reagenda-1';

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

final _manana = DateTime.now().toUtc().add(const Duration(days: 1));

JobModel _job({String status = 'aceptado', DateTime? at}) => JobModel(
      id: 'job-r1',
      userId: fakeUserId,
      workerId: _pro,
      serviceId: 'svc-1',
      status: status,
      address: 'Av. Diego Portales 860',
      scheduledDate: at ?? _manana,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

Map<String, dynamic> _prop(String id, String estado, String por) => {
      'id': id,
      'id_trabajo': 'job-r1',
      'propuesta_por': por,
      'rol_proponente': por == _pro ? 'trabajador' : 'cliente',
      'fecha_anterior': _manana.toIso8601String(),
      'fecha_propuesta':
          _manana.add(const Duration(hours: 3)).toIso8601String(),
      'estado': estado,
      'motivo': 'Se me cruzó otra visita',
      'respondida_por': estado == 'pendiente' ? null : fakeUserId,
      'respondida_en': estado == 'pendiente' ? null : '2026-05-02T10:00:00Z',
      'creado_en': '2026-05-01T10:00:00Z',
    };

void _rpcs(FakeBackend b, {bool horas = true}) {
  final respuesta = _prop('nueva', 'pendiente', fakeUserId);
  for (final r in [
    'proponer_reprogramacion',
    'responder_reprogramacion',
    'retirar_reprogramacion',
  ]) {
    b.rpc(r, respuesta);
  }
  b.rpc('horarios_libres_profesional', [
    if (horas)
      for (var h = 3; h < 30; h += 3)
        {
          'inicio':
              DateTime.now().toUtc().add(Duration(hours: h)).toIso8601String(),
        },
  ]);
}

Widget _seccion(JobModel job) => Scaffold(
      body: SingleChildScrollView(
        child: RescheduleSection(
          job: job,
          currentUserId: fakeUserId,
          onChanged: () async {},
        ),
      ),
    );

Future<void> _proponer(WidgetTester t) async {
  await _pasos(t, 4);
  if (!await _tap(t, find.text('Reagendar'))) return;
  await _tap(t, find.text('Cancelar'));
  await _tap(t, find.text('Reagendar'));
  final dd = find.byType(DropdownButtonFormField<DateTime>);
  if (dd.evaluate().isNotEmpty) {
    await _tap(t, dd.first);
    final items = find.byType(DropdownMenuItem<DateTime>);
    if (items.evaluate().length > 1) {
      await t.tap(items.last, warnIfMissed: false);
      await _pasos(t, 2);
    }
  }
  final campo = find.byType(TextField);
  if (campo.evaluate().isNotEmpty) {
    await t.enterText(campo.last, 'Tengo otra visita a esa hora');
    await t.pump();
  }
  await _tap(t, find.text('Enviar propuesta'));
  await _tap(t, find.text('Cerrar'));
  await _tap(t, find.text('Entendido'));
  await _pasos(t, 3);
}

void main() {
  testWidgets('proponer otra hora', (t) async {
    await smokeWidget(t, () => _seccion(_job()),
        interact: false, role: 'usuario', setup: (b) {
      b.seed('reprogramaciones_trabajo', [
        _prop('p1', 'aceptada', _pro),
        _prop('p2', 'rechazada', fakeUserId),
        _prop('p3', 'retirada', _pro),
      ]);
      _rpcs(b);
    }, script: _proponer);
  });

  testWidgets('proponer sin horas libres y con error', (t) async {
    await smokeWidget(t, () => _seccion(_job(status: 'pendiente')),
        interact: false, role: 'usuario', setup: (b) {
      b.seed('reprogramaciones_trabajo', []);
      _rpcs(b, horas: false);
      b.rpcErrors['proponer_reprogramacion'] = 'Hora no disponible';
    }, script: _proponer);
  });

  testWidgets('falla al leer horas libres', (t) async {
    await smokeWidget(t, () => _seccion(_job()),
        interact: false, role: 'usuario', setup: (b) {
      b.seed('reprogramaciones_trabajo', []);
      _rpcs(b);
      b.failing.add('horarios_libres_profesional');
    }, script: _proponer);
  });

  for (final accion in ['Aceptar nueva hora', 'Rechazar']) {
    testWidgets('propuesta del profesional: $accion', (t) async {
      await smokeWidget(t, () => _seccion(_job()),
          interact: false, role: 'usuario', setup: (b) {
        b.seed('reprogramaciones_trabajo', [_prop('p1', 'pendiente', _pro)]);
        _rpcs(b);
        if (accion == 'Rechazar') {
          b.failing.add('responder_reprogramacion');
        }
      }, script: (t) async {
        await _pasos(t, 4);
        await _tap(t, find.text(accion));
        await _pasos(t, 3);
      });
    });
  }

  testWidgets('retirar mi propuesta', (t) async {
    await smokeWidget(t, () => _seccion(_job()),
        interact: false, role: 'usuario', setup: (b) {
      b.seed(
          'reprogramaciones_trabajo', [_prop('p1', 'pendiente', fakeUserId)]);
      _rpcs(b);
    }, script: (t) async {
      await _pasos(t, 4);
      await _tap(t, find.text('Retirar mi propuesta'));
      await _pasos(t, 3);
    });
  });

  testWidgets('trabajo en curso solo muestra historial', (t) async {
    await smokeWidget(t, () => _seccion(_job(status: 'en_curso')),
        interact: false,
        role: 'usuario',
        setup: (b) {
          b.seed('reprogramaciones_trabajo', [_prop('p1', 'aceptada', _pro)]);
        },
        script: (t) => _pasos(t, 4));
  });

  testWidgets('historial que no carga', (t) async {
    await smokeWidget(t, () => _seccion(_job()),
        interact: false,
        role: 'usuario',
        setup: (b) {
          b.failing.add('reprogramaciones_trabajo');
        },
        script: (t) => _pasos(t, 4));
  });
}
