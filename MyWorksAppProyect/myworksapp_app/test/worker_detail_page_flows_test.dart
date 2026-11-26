// WorkerDetailPage: ficha completa con resumen de reseñas, foto de perfil,
// portafolio corto y largo, solicitar servicio con y sin servicio resuelto,
// perfil público que falla y ficha que no carga.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/user/presentation/pages/worker_detail_page.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

const _pro = 'pro-detalle-1';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t);
}

void _ficha(FakeBackend b,
    {int fotos = 2, bool servicios = true, bool perfil = true}) {
  b.seed('trabajadores', [
    {
      ...sampleWorkerModel,
      'id_usuario': _pro,
      'disponible': 1,
      'categoria_servicio': 'plomeria',
      'descripcion': null,
    },
  ]);
  b.seed('trabajos', []);
  if (perfil) {
    b.rpc('perfiles_publicos_por_ids', [
      {
        'id': _pro,
        'nombre': 'Pedro Rojas',
        'rol': 'trabajador',
        'ruta_foto_perfil': 'perfiles/pedro.jpg',
      },
    ]);
  } else {
    b.rpcErrors['perfiles_publicos_por_ids'] = 'sin permiso';
  }
  b.seed('portafolio_trabajador', [
    for (var i = 0; i < fotos; i++)
      {
        ...samplePortfolioModel,
        'id': 'pf-$i',
        'id_trabajador': _pro,
        'tipo_medio': 'imagen',
      },
  ]);
  b.seed('ia_resumen_resenas', [
    {'id_profesional': _pro, 'resumen': 'Puntual y ordenado.'},
  ]);
  b.seed('servicios', [
    if (servicios)
      {
        ...sampleServiceModel,
        'id': 'svc-plom',
        'categoria': 'plomeria',
        'activo': 1,
      },
  ]);
}

Future<void> _recorrer(WidgetTester t) async {
  await _pasos(t, 5);
  await _tap(t, find.text('Omitir'));
  final avatar = find.byType(CircleAvatar);
  if (avatar.evaluate().isNotEmpty) {
    await _tap(t, avatar.first);
    await t.pageBack().catchError((_) {});
    await _pasos(t, 2);
  }
  await _tap(t, find.text('Crear solicitud de servicio'));
  await _pasos(t, 2);
}

void main() {
  testWidgets('ficha completa y solicitar', (t) async {
    await smokeWidget(t, () => const WorkerDetailPage(workerId: _pro),
        interact: false,
        role: 'usuario',
        size: const Size(430, 2400),
        setup: (b) => _ficha(b),
        script: _recorrer);
  });

  testWidgets('portafolio largo, sin servicio y sin perfil público', (t) async {
    await smokeWidget(t, () => const WorkerDetailPage(workerId: _pro),
        interact: false,
        role: 'usuario',
        size: const Size(430, 2400),
        setup: (b) => _ficha(b, fotos: 12, servicios: false, perfil: false),
        script: _recorrer);
  });

  testWidgets('sin portafolio', (t) async {
    await smokeWidget(t, () => const WorkerDetailPage(workerId: _pro),
        interact: false,
        role: 'usuario',
        size: const Size(430, 2400),
        setup: (b) => _ficha(b, fotos: 0),
        script: _recorrer);
  });

  testWidgets('la ficha no carga', (t) async {
    await smokeWidget(t, () => const WorkerDetailPage(workerId: _pro),
        interact: false,
        role: 'usuario',
        setup: (b) => b.failing.add('trabajadores'),
        script: (t) => _pasos(t, 4));
  });
}
