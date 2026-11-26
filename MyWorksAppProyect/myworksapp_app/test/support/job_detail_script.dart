// Guion reutilizable para JobDetailPage: siembra un trabajo por estado y rol y
// recorre una lista de pasos (tocar texto, escribir en un campo, PIN).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/jobs/presentation/pages/job_detail_page.dart';

import 'fake_supabase.dart';
import 'model_samples.dart';
import 'widget_harness.dart';

const detailJobId = '00000000-0000-4000-8000-0000000000aa';
const detailOtherId = '00000000-0000-4000-8000-0000000000c1';

Future<void> detailSteps(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<bool> detailTap(WidgetTester t, String texto) async {
  final f = find.text(texto);
  if (f.evaluate().isEmpty) return false;
  // La acción del pie (o el botón del diálogo) es la última coincidencia.
  await t.ensureVisible(f.last);
  await t.pump();
  await t.tap(f.last, warnIfMissed: false);
  await detailSteps(t, 4);
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
  await detailTap(t, 'Confirmar PIN');
}

Future<void> _campo(WidgetTester t, String etiqueta, String valor) async {
  final f = find.widgetWithText(TextField, etiqueta);
  final campo = f.evaluate().isNotEmpty ? f : find.byType(TextField);
  if (campo.evaluate().isEmpty) return;
  await t.enterText(campo.last, valor);
  await t.pump();
}

class DetailCase {
  const DetailCase(
    this.name,
    this.role,
    this.status,
    this.steps, {
    this.extra = const {},
    this.evidence = 0,
    this.failing = const [],
    this.rpcErrors = const {},
    this.seed = const {},
    this.functionResult,
    this.width = 480,
    this.bounded = true,
  });
  final String name;
  final String role;
  final String status;

  /// Texto a tocar, 'PIN', o 'campo:Etiqueta=valor'.
  final List<String> steps;
  final Map<String, dynamic> extra;
  final int evidence;
  final List<String> failing;
  final Map<String, String> rpcErrors;
  final Map<String, List<Map<String, dynamic>>> seed;
  final Object? functionResult;
  final double width;
  final bool bounded;
}

Future<void> runDetailCase(WidgetTester t, DetailCase c) async {
  await smokeWidget(
    t,
    () => const JobDetailPage(jobId: detailJobId),
    role: c.role,
    interact: false,
    size: Size(c.width, 3600),
    boundedButtons: c.bounded,
    setup: (b) {
      final worker = c.role == 'trabajador';
      b.seed('trabajos', [
        {
          ...universalRow,
          ...sampleJobModel,
          'id': detailJobId,
          'estado': c.status,
          'id_usuario': worker ? detailOtherId : fakeUserId,
          'id_trabajador': worker ? fakeUserId : detailOtherId,
          'metadatos_servicio': <String, dynamic>{},
          'modalidad_cobro': 'precio_fijo',
          ...c.extra,
        },
      ]);
      b.seed('fotos_trabajo', [
        for (var i = 0; i < c.evidence; i++)
          {
            'id': 'ev$i',
            'id_trabajo': detailJobId,
            'ruta_foto': '$detailJobId/$fakeUserId/ev$i.webp',
            'tipo_medio': 'foto',
            'creado_en': '2026-11-20T10:00:00Z',
          },
      ]);
      b.seed('disputas', []);
      for (final e in c.seed.entries) {
        b.seed(e.key, e.value);
      }
      b.failing.addAll(c.failing);
      b.rpcErrors.addAll(c.rpcErrors);
      if (c.functionResult != null) {
        b.defaultFunction = (_) => c.functionResult;
      }
    },
    script: (t) async {
      await detailSteps(t, 6);
      for (final p in c.steps) {
        if (p == 'PIN') {
          await _pin(t);
        } else if (p.startsWith('campo:')) {
          final kv = p.substring(6).split('=');
          await _campo(t, kv[0], kv.sublist(1).join('='));
        } else {
          await detailTap(t, p);
        }
      }
      await detailSteps(t, 4);
    },
  );
}
