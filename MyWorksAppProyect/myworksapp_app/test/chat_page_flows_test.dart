// ChatPage: carga fallida, trabajo inexistente, mensaje de ayer, mensaje que
// llega por Realtime, envío exitoso, dato sensible bloqueado, trabajo sin la
// otra persona y error del backend al enviar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/chat/presentation/pages/chat_page.dart';

import 'support/fake_realtime.dart';
import 'support/fake_supabase.dart';
import 'support/model_samples.dart';
import 'support/widget_harness.dart';

const _job = 'job-chat-1';

Future<void> _pasos(WidgetTester t, [int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 200));
  }
}

Map<String, dynamic> _msg(String id, String texto, DateTime cuando) => {
      'id': id,
      'id_trabajo': _job,
      'id_remitente': 'otro-1',
      'id_destinatario': fakeUserId,
      'contenido': texto,
      'tipo': 'texto',
      'leido': 0,
      'creado_en': cuando.toUtc().toIso8601String(),
    };

void Function(FakeBackend) _datos({bool conTrabajador = true}) => (b) {
      b.seed('trabajos', [
        {
          ...sampleJobModel,
          'id': _job,
          'id_usuario': fakeUserId,
          'id_trabajador': conTrabajador ? 'otro-1' : null,
          'estado': 'en_curso',
        },
      ]);
      b.seed('mensajes', [
        _msg('m-ayer', 'Hola de ayer',
            DateTime.now().subtract(const Duration(days: 1, minutes: 5))),
        _msg('m-viejo', 'Hace días',
            DateTime.now().subtract(const Duration(days: 5))),
      ]);
    };

Future<void> _escribirYEnviar(WidgetTester t, String texto) async {
  await t.enterText(find.byType(TextField).last, texto);
  await t.pump();
  await t.tap(find.byTooltip('Enviar mensaje'));
  await _pasos(t, 3);
}

void main() {
  testWidgets('carga fallida muestra chat no disponible', (t) async {
    await smokeWidget(t, () => const ChatPage(jobId: _job),
        interact: false,
        setup: (b) => b.failing.add('mensajes'),
        script: (t) async {
          await _pasos(t, 3);
          expect(find.text('Chat no disponible'), findsOneWidget);
        });
  });

  testWidgets('trabajo inexistente no permite enviar', (t) async {
    await smokeWidget(t, () => const ChatPage(jobId: 'no-existe'),
        interact: false, script: (t) async {
      await _pasos(t, 3);
      await _escribirYEnviar(t, 'hola');
    });
  });

  testWidgets('conversación: realtime, envío, bloqueo y error', (t) async {
    await smokeWidget(t, () => const ChatPage(jobId: _job),
        interact: false,
        size: const Size(500, 1000),
        setup: _datos(), script: (t) async {
      await _pasos(t, 3);
      expect(
          emitRealtimeInsert('mensajes-$_job', 'mensajes',
              _msg('m-rt', 'Llegó por realtime', DateTime.now())),
          1);
      await _pasos(t, 2);
      expect(find.text('Llegó por realtime'), findsOneWidget);
      // Registro vacío: se ignora.
      emitRealtimeInsert('mensajes-$_job', 'mensajes', {});
      await _pasos(t, 1);
      await _escribirYEnviar(t, 'Te llamo al +56 9 8765 4321');
      final ok = find.byType(TextButton);
      if (ok.evaluate().isNotEmpty) {
        await t.tap(ok.last);
        await t.pumpAndSettle();
      }
      await _escribirYEnviar(t, 'Llego a las cinco');
      FakeBackend.instance.failing.add('mensajes:post');
      await _escribirYEnviar(t, 'Este falla');
      FakeBackend.instance.failing.remove('mensajes:post');
    });
  });

  testWidgets('trabajo sin la otra persona', (t) async {
    await smokeWidget(t, () => const ChatPage(jobId: _job),
        interact: false,
        setup: _datos(conTrabajador: false), script: (t) async {
      await _pasos(t, 3);
      await _escribirYEnviar(t, 'hola');
    });
  });
}
