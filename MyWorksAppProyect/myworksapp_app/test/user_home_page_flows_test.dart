// UserHomePage: búsqueda con y sin resultados, abrir un servicio, consola de
// administrador, perfil, error al cargar servicios con reintento y volver a
// primer plano.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/service_model.dart';
import 'package:myworksapp/core/widgets/design_system/service_card.dart';
import 'package:myworksapp/features/user/presentation/pages/user_home_page.dart';

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

Future<bool> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return false;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t);
  return true;
}

void _servicios(FakeBackend b) {
  b.functions['oneclick-charge'] = (_) => {'enrolled': true, 'last4': '4242'};
  b.seed('servicios', [
    for (final c in [
      ServiceCategories.plumbing,
      ServiceCategories.electrical,
      ServiceCategories.cleaning,
      ServiceCategories.gardening,
    ])
      {
        ...sampleServiceModel,
        'id': 'svc-$c',
        'categoria': c,
        'nombre': 'Servicio $c',
        'descripcion': 'Descripción de $c',
        'activo': 1,
      },
  ]);
}

Future<void> _buscar(WidgetTester t, String q) async {
  final campo = find.byType(TextField);
  if (campo.evaluate().isEmpty) return;
  await t.enterText(campo.first, q);
  await _pasos(t, 2);
}

void main() {
  for (final rol in ['usuario', 'administrador']) {
    testWidgets('inicio con servicios ($rol)', (t) async {
      await smokeWidget(t, () => const UserHomePage(),
          interact: false,
          role: rol,
          size: const Size(430, 1400),
          setup: _servicios, script: (t) async {
        await _pasos(t, 4);
        await _tap(t, find.text('Ahora no'));
        await _tap(t, find.text('Omitir'));
        await _buscar(t, 'gasfiter');
        await _buscar(t, 'zzzz-nada');
        await _buscar(t, 'jardin');
        await _buscar(t, '');
        final card = find.byType(ServiceCard);
        if (card.evaluate().isNotEmpty) {
          await _tap(t, card.first);
          await t.pageBack().catchError((_) {});
          await _pasos(t, 2);
        }
        await _tap(t, find.text('Consola de administración'));
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await _pasos(t, 2);
      });
    });
  }

  for (final accion in [
    'Ver trabajo',
    'Encuesta de la prueba',
    'Ver todos ›',
    'Mis Proyectos',
    'Avisos',
    'Mensajes',
    'Perfil',
    'Consola de administración',
  ]) {
    testWidgets('acción: $accion', (t) async {
      await smokeWidget(t, () => const UserHomePage(),
          interact: false,
          role: accion.startsWith('Consola') ? 'administrador' : 'usuario',
          size: const Size(430, 1400),
          setup: _servicios, script: (t) async {
        await _pasos(t, 4);
        await _tap(t, find.text('Omitir'));
        await _buscar(t, 'luz');
        await _tap(t, find.text(accion));
        await _pasos(t, 3);
      });
    });
  }

  testWidgets('sin servicios', (t) async {
    await smokeWidget(t, () => const UserHomePage(),
        interact: false,
        setup: (b) => b.seed('servicios', []),
        script: (t) async {
          await _pasos(t, 4);
          await _tap(t, find.text('Omitir'));
        });
  });

  testWidgets('error al cargar servicios y reintento', (t) async {
    await smokeWidget(t, () => const UserHomePage(),
        interact: false,
        setup: (b) => b.failing.add('servicios'),
        script: (t) async {
          await _pasos(t, 4);
          await _tap(t, find.text('Omitir'));
          FakeBackend.instance.failing.remove('servicios');
          _servicios(FakeBackend.instance);
          await _tap(t, find.text('Reintentar'));
          await _pasos(t, 3);
        });
  });
}
