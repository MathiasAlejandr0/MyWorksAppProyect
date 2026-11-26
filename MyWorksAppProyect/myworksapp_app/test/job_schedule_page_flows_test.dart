// JobSchedulePage: trabajos del día en el calendario, elegir otro día, hora
// repetida (aviso), guardar horario con error y quitar una hora.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/pages/job_schedule_page.dart';
import 'package:myworksapp/features/worker/presentation/widgets/worker_hours_editor.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

void _datos(FakeBackend b) {
  final hoy = DateTime.now().toUtc().add(const Duration(hours: 1));
  b.seed('trabajos', [
    for (final estado in ['aceptado', 'en_curso', 'completado', 'cancelado'])
      {
        ...sampleJobModel,
        'id': 'agenda-$estado',
        'id_trabajador': fakeUserId,
        'estado': estado,
        'descripcion': estado == 'cancelado' ? null : 'Trabajo $estado',
        'fecha_programada': hoy.toIso8601String(),
      },
  ]);
  b.seed('trabajadores', [
    {
      ...sampleWorkerModel,
      'id_usuario': fakeUserId,
      'horas_publicadas': [
        {'dia': 1, 'hora': '09:00'},
        {'dia': 1, 'hora': '10:00'},
      ],
    },
  ]);
}

void main() {
  testWidgets('agenda con trabajos y horas', (t) async {
    await smokeWidget(t, () => const JobSchedulePage(),
        interact: false,
        role: 'trabajador',
        size: const Size(500, 1800),
        setup: _datos, script: (t) async {
      await _pasos(t, 4);
      final editor =
          t.widget<WorkerHoursEditor>(find.byType(WorkerHoursEditor));
      editor.onSelectWeekday(1);
      await _pasos(t, 1);
      // Hora repetida: aviso; luego una nueva con error al guardar.
      await t
          .widget<WorkerHoursEditor>(find.byType(WorkerHoursEditor))
          .onAddHour(const TimeOfDay(hour: 9, minute: 0));
      await _pasos(t, 1);
      FakeBackend.instance.failAll = true;
      await t
          .widget<WorkerHoursEditor>(find.byType(WorkerHoursEditor))
          .onAddHour(const TimeOfDay(hour: 15, minute: 0));
      await _pasos(t, 2);
      FakeBackend.instance.failAll = false;
      final horas =
          t.widget<WorkerHoursEditor>(find.byType(WorkerHoursEditor)).hours;
      if (horas.isNotEmpty) {
        t
            .widget<WorkerHoursEditor>(find.byType(WorkerHoursEditor))
            .onRemoveHour(horas.first);
        await _pasos(t, 2);
      }
      // Elegir otro día del calendario y volver.
      final dia = find.text('15');
      if (dia.evaluate().isNotEmpty) {
        await t.tap(dia.first, warnIfMissed: false);
        await _pasos(t, 1);
      }
      final hoy = find.text('${DateTime.now().day}');
      if (hoy.evaluate().isNotEmpty) {
        await t.tap(hoy.first, warnIfMissed: false);
        await _pasos(t, 2);
      }
    });
  });
}
