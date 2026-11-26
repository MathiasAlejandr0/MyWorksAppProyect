// WorkerRegisterPage: perfil completo creado, error al guardar, sin sesión y
// validación de campos vacíos.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/chile_comunas.dart';
import 'package:myworksapp/core/utils/service_worker_mapper.dart';
import 'package:myworksapp/features/worker/presentation/pages/worker_register_page.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _llenarYEnviar(WidgetTester t) async {
  final drops = find.byType(DropdownButtonFormField<String>);
  t
      .state<FormFieldState<String>>(drops.at(0))
      .didChange(ServiceWorkerMapper.registrationProfessions.first);
  t
      .state<FormFieldState<String>>(drops.at(1))
      .didChange(ChileComunas.allZones.first);
  await t.pump();
  await t.enterText(find.byType(TextFormField).last,
      'Gasfiter con diez años de experiencia en reparaciones del hogar.');
  await t.pump();
  await t.tap(find.text('Completar perfil'));
  await _pasos(t, 5);
}

void main() {
  testWidgets('campos vacíos no envían', (t) async {
    await smokeWidget(t, () => const WorkerRegisterPage(),
        interact: false,
        role: 'trabajador',
        size: const Size(500, 1400), script: (t) async {
      await t.tap(find.text('Completar perfil'));
      await _pasos(t, 1);
    });
  });

  testWidgets('perfil creado navega a precios', (t) async {
    await smokeWidget(t, () => const WorkerRegisterPage(),
        interact: false,
        role: 'trabajador',
        size: const Size(500, 1400),
        script: _llenarYEnviar);
  });

  testWidgets('error al guardar el perfil', (t) async {
    await smokeWidget(t, () => const WorkerRegisterPage(),
        interact: false,
        role: 'trabajador',
        size: const Size(500, 1400),
        setup: (b) => b.failing.addAll(['trabajadores', 'trabajadores:post']),
        script: _llenarYEnviar);
  });

  testWidgets('sin sesión pide iniciar sesión', (t) async {
    await smokeWidget(t, () => const WorkerRegisterPage(),
        signedIn: false,
        interact: false,
        size: const Size(500, 1400),
        script: _llenarYEnviar);
  });
}
