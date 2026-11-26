// Acciones del detalle de trabajo con un trabajo sembrado por estado y rol:
// aceptar, rechazar, en camino, iniciar con PIN, finalizar y cancelar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/pages/job_detail_page.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

const _job = '00000000-0000-4000-8000-0000000000aa';
const _otro = '00000000-0000-4000-8000-0000000000c1';

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<bool> _tap(WidgetTester t, String texto) async {
  final f = find.text(texto);
  if (f.evaluate().isEmpty) return false;
  // La acción del pie (o el botón del diálogo) es la última coincidencia.
  await t.ensureVisible(f.last);
  await t.pump();
  await t.tap(f.last, warnIfMissed: false);
  await _pasos(t, 4);
  return true;
}

Future<void> _pin(WidgetTester t) async {
  final campos = find.byType(TextField);
  if (campos.evaluate().isNotEmpty) {
    await t.enterText(campos.first, '1234');
    await t.pump();
  } else {
    for (final d in ['1', '2', '3', '4']) {
      final k = find.text(d);
      if (k.evaluate().isNotEmpty) {
        await t.tap(k.last, warnIfMissed: false);
        await t.pump();
      }
    }
  }
  await _tap(t, 'Confirmar PIN');
}

class _Caso {
  const _Caso(this.nombre, this.rol, this.estado, this.pasos,
      {this.extra = const {},
      this.evidencia = 0,
      this.fallaRpc,
      this.rpcError});
  final String nombre;
  final String rol;
  final String estado;
  final List<String> pasos; // 'PIN' escribe el PIN
  final Map<String, dynamic> extra;
  final int evidencia;
  final String? fallaRpc;
  final String? rpcError;
}

const _casos = [
  _Caso('aceptar', 'trabajador', 'pendiente', ['Aceptar Trabajo']),
  _Caso('aceptar con error', 'trabajador', 'pendiente', ['Aceptar Trabajo'],
      fallaRpc: 'asignar_trabajador_trabajo'),
  _Caso('rechazar y desistir', 'trabajador', 'pendiente',
      ['Rechazar', 'No', 'Rechazar', 'Sí, rechazar']),
  _Caso('rechazar invitación', 'trabajador', 'pendiente', [
    'Rechazar',
    'Sí, rechazar'
  ], extra: {
    'metadatos_servicio': {'request_type': 'worker_tier_invitation'}
  }),
  _Caso('en camino', 'trabajador', 'aceptado', ['Voy en camino']),
  _Caso('en camino con error', 'trabajador', 'aceptado', ['Voy en camino'],
      fallaRpc: 'transicionar_trabajo'),
  _Caso(
      'iniciar con PIN', 'trabajador', 'en_camino', ['Iniciar trabajo', 'PIN']),
  _Caso('iniciar con PIN incorrecto', 'trabajador', 'en_camino',
      ['Iniciar trabajo', 'PIN', 'PIN', 'Cancelar'],
      rpcError: 'PIN incorrecto, te quedan 2 intentos'),
  _Caso('iniciar con otro error', 'trabajador', 'en_camino',
      ['Iniciar trabajo', 'PIN'],
      rpcError: 'estado no permite iniciar'),
  _Caso('finalizar sin evidencia', 'trabajador', 'en_curso', [
    'Finalizar Trabajo',
    'Cancelar',
    'Finalizar Trabajo',
    'Subir evidencia'
  ]),
  _Caso('finalizar con evidencia', 'trabajador', 'en_curso',
      ['Finalizar Trabajo'],
      evidencia: 2),
  _Caso('finalizar invitación', 'trabajador', 'en_curso',
      ['Finalizar y enviar evidencia'],
      evidencia: 1,
      extra: {
        'metadatos_servicio': {'request_type': 'worker_tier_invitation'},
        'modo_precio': 'bloque_horas',
      }),
  _Caso('finalizar con error', 'trabajador', 'en_curso', ['Finalizar Trabajo'],
      evidencia: 1, fallaRpc: 'transicionar_trabajo'),
  _Caso('cancelar solicitud', 'usuario', 'pendiente',
      ['Cancelar Solicitud', 'No', 'Cancelar Solicitud', 'Sí, cancelar']),
  _Caso('calificar', 'usuario', 'completado', ['Calificar Trabajo']),
];

void main() {
  for (final c in _casos) {
    testWidgets('JobDetailPage: ${c.nombre}', (t) async {
      await smokeWidget(
        t,
        () => const JobDetailPage(jobId: _job),
        role: c.rol,
        interact: false,
        size: const Size(480, 3600),
        boundedButtons: true,
        setup: (b) {
          final esTrabajador = c.rol == 'trabajador';
          b.seed('trabajos', [
            {
              ...universalRow,
              ...sampleJobModel,
              'id': _job,
              'estado': c.estado,
              'id_usuario': esTrabajador ? _otro : fakeUserId,
              'id_trabajador': esTrabajador ? fakeUserId : _otro,
              'metadatos_servicio': <String, dynamic>{},
              'modo_precio': 'precio_fijo',
              ...c.extra,
            },
          ]);
          b.seed('fotos_trabajo', [
            for (var i = 0; i < c.evidencia; i++)
              {
                'id': 'ev$i',
                'id_trabajo': _job,
                'ruta_foto': '$_job/$fakeUserId/ev$i.webp',
                'tipo_medio': 'foto',
                'creado_en': '2026-11-20T10:00:00Z',
              },
          ]);
          b.seed('disputas', []);
          if (c.fallaRpc != null) b.failing.add(c.fallaRpc!);
          if (c.rpcError != null) {
            b.rpcErrors['transicionar_trabajo'] = c.rpcError!;
          }
        },
        script: (t) async {
          await _pasos(t, 6);
          for (final p in c.pasos) {
            if (p == 'PIN') {
              await _pin(t);
            } else {
              await _tap(t, p);
            }
          }
          await _pasos(t, 4);
        },
      );
    });
  }
}
