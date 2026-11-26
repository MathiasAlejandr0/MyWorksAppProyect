// AdminRankingPage: mover cada peso, guardar, aprender (con y sin muestra),
// resolver reseñas dudosas desde el menú y errores de cada RPC.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/admin/presentation/pages/admin_ranking_page.dart';

import 'support/fake_supabase.dart';
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

Map<String, dynamic> _senal(int i) => {
      'id': 'sen-$i',
      'id_calificacion': 'cal-$i',
      'tipo_senal': i.isEven ? 'texto_repetido' : 'rafaga',
      'puntaje': 0.8,
      'estado': 'pendiente',
      'creado_en': '2026-05-0${i + 1}T10:00:00Z',
      'detalle': 'Detalle $i',
      'puntaje_resena': 5,
      'comentario': i == 0 ? null : 'Excelente',
      'nombre_cliente': 'Cliente $i',
      'nombre_trabajador': 'Pro $i',
    };

void _rpcs(FakeBackend b, {bool aprende = true}) {
  b.rpc('obtener_config_ranking', {
    'peso_calificacion': 0.3,
    'peso_completados': 0.2,
    'peso_rechazos': 0.1,
    'peso_verificacion': 0.1,
    'peso_impulso': 0.1,
    'peso_recencia': 0.1,
    'peso_confianza': 0.1,
  });
  b.rpc('guardar_config_ranking', {'peso_calificacion': 0.5});
  b.rpc('listar_senales_resena', [for (var i = 0; i < 3; i++) _senal(i)]);
  b.rpc('resolver_senal_resena', null);
  b.rpc(
      'aprender_pesos_ranking_admin',
      aprende
          ? {'ok': true, 'positivos': 12, 'negativos': 1}
          : {'ok': false, 'motivo': 'muestra chica'});
}

Future<void> _recorrer(WidgetTester t) async {
  await _pasos(t, 4);
  for (final s in find.byType(Slider).evaluate().toList()) {
    await t.drag(find.byWidget(s.widget), const Offset(40, 0),
        warnIfMissed: false);
    await t.pump();
  }
  await _tap(t, find.text('Guardar y recalcular'));
  await _tap(t, find.text('Aprender ahora'));
  await _tap(t, find.text('Reseñas dudosas'));
  for (final opcion in ['Es falsa alarma', 'Confirmar fraude', 'Descartar']) {
    final menu = find.byType(PopupMenuButton<String>);
    if (menu.evaluate().isEmpty) break;
    await _tap(t, menu.first);
    await _tap(t, find.text(opcion));
  }
  await _tap(t, find.text('Fraude'));
  await _tap(t, find.text('Falsos positivos'));
  await _tap(t, find.text('Pendientes'));
}

void main() {
  testWidgets('pesos, aprendizaje y reseñas', (t) async {
    await smokeWidget(t, () => const AdminRankingPage(),
        interact: false,
        role: 'administrador',
        size: const Size(900, 2000),
        setup: (b) => _rpcs(b),
        script: _recorrer);
  });

  testWidgets('sin muestra y errores al guardar y resolver', (t) async {
    await smokeWidget(t, () => const AdminRankingPage(),
        interact: false,
        role: 'administrador',
        size: const Size(900, 2000), setup: (b) {
      _rpcs(b, aprende: false);
      b.rpcErrors['guardar_config_ranking'] = 'sin permiso';
      b.rpcErrors['resolver_senal_resena'] = 'sin permiso';
    }, script: _recorrer);
  });

  testWidgets('falla al aprender y al cargar', (t) async {
    await smokeWidget(t, () => const AdminRankingPage(),
        interact: false,
        role: 'administrador',
        size: const Size(900, 2000), setup: (b) {
      _rpcs(b);
      b.rpcErrors['aprender_pesos_ranking_admin'] = 'caído';
    }, script: _recorrer);
    await smokeWidget(t, () => const AdminRankingPage(),
        interact: false,
        role: 'administrador',
        setup: (b) => b.rpcErrors['obtener_config_ranking'] = 'caído',
        script: (t) => _pasos(t, 3));
  });
}
