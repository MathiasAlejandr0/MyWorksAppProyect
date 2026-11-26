// WebAiAssistantWidget (motor local, sin Gemini): consultas rápidas y escritas
// con profesionales del catálogo, sin profesionales y en tema oscuro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/theme/app_theme.dart';
import 'package:myworksapp/core/widgets/design_system/web_ai_assistant_widget.dart';

import 'support/catalog_seed.dart';
import 'support/widget_harness.dart';

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

Future<void> _consultas(WidgetTester t) async {
  await _pasos(t, 2);
  // Vacía: no hace nada.
  await _tap(t, find.text('Evaluar con IA'));
  for (final chip in [
    '🔧 Fuga de agua en lavaplatos',
    '⚡ Enchufe quemado en la cocina',
    '🚚 Flete con camión para traslado',
  ]) {
    await _tap(t, find.text(chip));
    await _pasos(t, 2);
  }
  await t.enterText(find.byType(TextField).first, 'Se cortó la luz del baño');
  await _tap(t, find.text('Evaluar con IA'));
  await _pasos(t, 2);
}

Widget _w() =>
    const Scaffold(body: SingleChildScrollView(child: WebAiAssistantWidget()));

void main() {
  for (final oscuro in [false, true]) {
    testWidgets('con profesionales del catálogo (oscuro $oscuro)', (t) async {
      await smokeWidget(
          t, () => oscuro ? Theme(data: AppTheme.darkTheme, child: _w()) : _w(),
          interact: false, size: const Size(900, 2200), setup: (b) {
        b.rpc('listar_profesionales_catalogo',
            [for (var i = 0; i < 3; i++) catalogPro(i)]);
      }, script: _consultas);
    });
  }

  testWidgets('sin profesionales disponibles', (t) async {
    await smokeWidget(t, _w,
        interact: false,
        size: const Size(900, 2200),
        setup: (b) => b.rpc('listar_profesionales_catalogo', []),
        script: _consultas);
  });

  testWidgets('sin la RPC usa la tabla de profesionales', (t) async {
    await smokeWidget(t, _w,
        interact: false,
        size: const Size(900, 2200),
        setup: (b) => b.rpcErrors['listar_profesionales_catalogo'] = 'no',
        script: _consultas);
  });
}
