// NotificationListenerScope: banner al llegar una notificación por Realtime,
// abrirla (trabajo / lista), cerrarla, expiración a los 6 s y logout.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/notification_realtime_service.dart';
import 'package:myworksapp/core/widgets/notification_listener_scope.dart';
import 'package:myworksapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/fake_realtime.dart';
import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

Map<String, dynamic> _noti(String id, String tipo, {String? rel}) => {
      'id': id,
      'id_usuario': fakeUserId,
      'tipo': tipo,
      'titulo': 'Titulo $id',
      'cuerpo': 'Cuerpo $id',
      'id_relacionado': rel,
      'leido': 0,
      'creado_en': '2026-11-26T12:00:00Z',
    };

Widget _host() => Consumer(
      builder: (ctx, ref, _) => NotificationListenerScope(
        child: Center(
          child: TextButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            child: const Text('salir'),
          ),
        ),
      ),
    );

Future<void> _llega(WidgetTester t, Map<String, dynamic> n) async {
  // La sesión ya existía al montar: suscribir como lo haría el login.
  await t.runAsync(() async {
    await NotificationRealtimeService.instance.unsubscribe();
    await NotificationRealtimeService.instance.subscribe(fakeUserId);
  });
  await _pasos(t, 1);
  expect(emitRealtimeInsert('notificaciones', 'notificaciones', n), 1);
  await _pasos(t, 2);
}

void main() {
  for (final (tipo, rel) in [
    ('job_accepted', 'job-1'),
    ('change_order_created', 'job-2'),
    ('mensaje', null),
  ]) {
    testWidgets('abrir notificación $tipo', (t) async {
      await smokeWidget(t, _host, interact: false, size: const Size(500, 900),
          script: (t) async {
        await _llega(t, _noti('n-$tipo', tipo, rel: rel));
        final banner = find.text('Titulo n-$tipo');
        expect(banner, findsOneWidget);
        await t.tap(banner);
        await _pasos(t, 2);
      });
    });
  }

  testWidgets('cerrar banner, expiración y logout', (t) async {
    await smokeWidget(t, _host, interact: false, size: const Size(500, 900),
        script: (t) async {
      await _llega(t, _noti('n1', 'sistema'));
      await t.tap(find.byTooltip('Cerrar'));
      await t.pump();
      await _llega(t, _noti('n2', 'sistema'));
      await _llega(t, _noti('n3', 'sistema'));
      await t.pump(const Duration(seconds: 7));
      // Registro malformado: se registra el error y no aparece banner.
      expect(
          emitRealtimeInsert('notificaciones', 'notificaciones', {'id': 'x'}),
          1);
      await _pasos(t, 1);
      await t.tap(find.text('salir'));
      await _pasos(t, 3);
    });
  });
}
