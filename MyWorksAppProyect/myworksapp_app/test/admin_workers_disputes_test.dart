// Admin: trabajadores (menú de disponibilidad, prioridad y estado de cuenta)
// y disputas (en revisión y resolución) con datos sembrados.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/admin/presentation/pages/admin_disputes_page.dart';
import 'package:myworksapp/features/admin/presentation/pages/admin_workers_page.dart';

import 'support/catalog_seed.dart';
import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

/// Abre el menú de la fila [fila] y elige [opcion] si aparece.
Future<void> _menu(WidgetTester t, String opcion, {int fila = 0}) async {
  final menus = find.byType(PopupMenuButton<String>);
  if (menus.evaluate().length <= fila) return;
  await t.tap(menus.at(fila), warnIfMissed: false);
  await _pasos(t, 2);
  final item = find.text(opcion);
  if (item.evaluate().isEmpty) {
    await t.tapAt(const Offset(5, 5));
    await _pasos(t, 2);
    return;
  }
  await t.tap(item.last, warnIfMissed: false);
  await _pasos(t, 4);
}

Map<String, dynamic> _trabajador(int i, {bool disponible = true}) => {
      ...catalogPro(i),
      'disponible': disponible ? 1 : 0,
      'prioridad_manual': i == 1 ? 48 : 0,
      'score_listado': 10.0 - i,
      'perfiles': {
        'nombre': i == 3 ? '' : 'Pro $i',
        'correo': 'pro$i@x.cl',
        'estado_cuenta': 'activo',
      },
    };

Map<String, dynamic> _disputa(int i, String estado) => {
      'id': 'disp-$i',
      'id_trabajo': '00000000-0000-4000-8000-00000000077$i',
      'abierta_por': fakeUserId,
      'motivo': 'calidad',
      'descripcion': i.isEven ? null : 'No quedó bien',
      'estado': estado,
      'creado_en': '2026-11-2${i}T10:00:00Z',
      'actualizado_en': '2026-11-2${i}T10:00:00Z',
    };

void main() {
  for (final falla in [false, true]) {
    testWidgets('AdminWorkersPage menú de acciones (falla=$falla)', (t) async {
      await smokeWidget(
        t,
        () => const AdminWorkersPage(),
        role: 'admin',
        interact: false,
        setup: (b) {
          b.seed('trabajadores', [
            _trabajador(1),
            _trabajador(2, disponible: false),
            _trabajador(3),
          ]);
          if (falla) {
            b.failing.addAll(['trabajadores:patch', 'perfiles:patch']);
            b.rpc('admin_actualizar_estado_cuenta', null);
            b.failing.add('admin_actualizar_estado_cuenta');
          }
        },
        script: (t) async {
          await _pasos(t, 4);
          for (final op in [
            'Marcar no disponible',
            'Mostrar más arriba',
            'Mostrar más abajo',
            'Quitar prioridad manual',
            'Activar cuenta',
          ]) {
            await _menu(t, op);
          }
          await _menu(t, 'Marcar disponible', fila: 1);
          final menus = find.byType(PopupMenuButton<String>);
          if (menus.evaluate().isNotEmpty) {
            await t.tap(menus.first, warnIfMissed: false);
            await _pasos(t, 2);
            final items = find.byType(PopupMenuItem<String>);
            if (items.evaluate().length > 5) {
              await t.tap(items.at(5), warnIfMissed: false);
              await _pasos(t, 4);
            } else {
              await t.tapAt(const Offset(5, 5));
              await _pasos(t, 2);
            }
          }
        },
      );
    });
  }

  for (final falla in [false, true]) {
    testWidgets('AdminDisputesPage revisión y resolución (falla=$falla)',
        (t) async {
      await smokeWidget(
        t,
        () => const AdminDisputesPage(),
        role: 'admin',
        interact: false,
        setup: (b) {
          b.seed('disputas', [
            _disputa(1, 'abierta'),
            _disputa(2, 'en_revision'),
            _disputa(3, 'resuelta'),
          ]);
          if (falla) b.failing.add('disputas:patch');
          b.defaultFunction = (_) => {'ok': true};
        },
        script: (t) async {
          await _pasos(t, 4);
          await _menu(t, 'Marcar en revisión');
          await _menu(t, 'Resolver');
          if (find.text('Resolver disputa').evaluate().isNotEmpty) {
            await t.tap(find.text('Cancelar').last);
            await _pasos(t, 3);
          }
          for (final decision in [
            'Devolver a la tarjeta',
            'Liberar al profesional',
          ]) {
            await _menu(t, 'Resolver');
            final campo = find.byType(TextField);
            if (campo.evaluate().isNotEmpty) {
              await t.enterText(campo.last, 'Se acordó devolver el dinero');
              await t.pump();
            }
            final f = find.text(decision);
            if (f.evaluate().isNotEmpty) {
              await t.tap(f.last, warnIfMissed: false);
              await _pasos(t, 6);
            }
          }
          for (final filtro in ['Todas', 'Resueltas', 'En revisión']) {
            final f = find.text(filtro);
            if (f.evaluate().isNotEmpty) {
              await t.tap(f.first, warnIfMissed: false);
              await _pasos(t, 3);
            }
          }
        },
      );
    });
  }
}
