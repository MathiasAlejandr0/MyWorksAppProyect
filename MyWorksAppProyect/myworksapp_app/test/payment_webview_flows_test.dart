// PaymentScreen y CardEnrollmentPage con el WebView falso: pago Webpay
// aprobado y rechazado, inscripción de tarjeta aprobada, rechazada y
// detectada por el sondeo, y la inscripción que lanza SavedCardTile.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/saved_card_tile.dart';
import 'package:myworksapp/features/payments/presentation/pages/card_enrollment_page.dart';
import 'package:myworksapp/features/payments/presentation/pages/payment_screen.dart';

import 'support/fake_supabase.dart';
import 'support/fake_webview.dart';
import 'support/widget_harness.dart';

const _ok = 'myworksapp://pago?pago=ok';
const _fail = 'myworksapp://pago?pago=fail';

late FakeWebViewPlatform _web;

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

/// Responde `oneclick-charge` según la acción; `cobros` se consume en orden.
void _oneclick(FakeBackend b,
    {List<Map<String, dynamic>> cobros = const [
      {'charged': true}
    ],
    Map<String, dynamic> inscribir = const {
      'handoffUrl': 'https://webpay3gint.transbank.cl/inscripcion'
    },
    bool inscrita = true}) {
  var n = 0;
  b.functions['oneclick-charge'] = (r) {
    final body = r.json is Map ? r.json as Map : const {};
    switch (body['action']) {
      case 'status':
        return inscrita
            ? {'enrolled': true, 'last4': '4242', 'cardType': 'Visa'}
            : {'enrolled': false};
      case 'enroll':
      case 'replace':
        return inscribir;
      case 'remove':
      case 'restore':
        return {'ok': true};
      default:
        return cobros[(n++) % cobros.length];
    }
  };
  b.functions['webpay-create'] = (_) => {
        'token': 'tok',
        'url': 'https://webpay3gint.transbank.cl/init',
        'buyOrder': 'BO-1',
        'paymentId': 'pay-1',
      };
  b.functions['webpay-status'] = (_) => {
        'payment': {'estado': 'pendiente'}
      };
}

bool? _resultado;

Widget _lanzador() => Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              _resultado = await PaymentScreen.open(context,
                  jobId: 'job-wv-1', amount: 30000, serviceName: 'Gasfitería');
            },
            child: const Text('Abrir pago'),
          ),
        ),
      ),
    );

Future<void> _retorno(WidgetTester t, String url) async {
  await _pasos(t, 2);
  final d = _web.delegate;
  if (d == null || d.onPageFinished == null) return;
  d.onPageFinished!(url);
  await _pasos(t, 3);
}

void main() {
  setUp(() {
    _web = FakeWebViewPlatform.install();
    _resultado = null;
  });

  for (final url in [_ok, _fail]) {
    testWidgets('Webpay sin guardar tarjeta: $url', (t) async {
      await smokeWidget(t, _lanzador,
          interact: false,
          role: 'usuario',
          setup: (b) => _oneclick(b),
          script: (t) async {
            await _pasos(t, 2);
            await _tap(t, find.text('Abrir pago'));
            await _tap(t, find.text('Pagar en Transbank sin guardar tarjeta'));
            await _retorno(t, url);
          });
      if (url == _ok) expect(_resultado, isTrue);
    });
  }

  for (final caso in ['aprobada', 'rechazada', 'cobro falla']) {
    testWidgets('sin tarjeta: inscripción $caso en el WebView', (t) async {
      await smokeWidget(t, _lanzador, interact: false, role: 'usuario',
          setup: (b) {
        _oneclick(b, inscrita: false, cobros: [
          {'needsCard': true},
          caso == 'cobro falla' ? {'charged': false} : {'charged': true},
        ]);
      }, script: (t) async {
        await _pasos(t, 2);
        await _tap(t, find.text('Abrir pago'));
        await _tap(t, find.text('Confirmar con tarjeta'));
        await _tap(t, find.text('Inscribir tarjeta'));
        await _retorno(t, caso == 'rechazada' ? _fail : _ok);
        // Tras el rechazo la página de inscripción sigue abierta.
        await _tap(t, find.text('Ahora no'));
      });
    });
  }

  testWidgets('la tarjeta quitada desde SavedCardTile abre la inscripción',
      (t) async {
    for (final inscribe in [true, false]) {
      await smokeWidget(t, _lanzador, interact: false, role: 'usuario',
          setup: (b) {
        _oneclick(b, inscribir: inscribe ? {'enrolled': true} : {'error': 'x'});
      }, script: (t) async {
        await _pasos(t, 2);
        await _tap(t, find.text('Abrir pago'));
        final tile = find.byType(SavedCardTile);
        if (tile.evaluate().isEmpty) return;
        final fut = t.widget<SavedCardTile>(tile).onCardRemoved();
        await _pasos(t, 2);
        if (inscribe) {
          await _tap(t, find.text('Inscribir tarjeta'));
        } else {
          await _tap(t, find.text('Ahora no'));
        }
        await _pasos(t, 3);
        await fut;
      });
    }
  });

  testWidgets('inscripción detectada por el sondeo', (t) async {
    await smokeWidget(
        t,
        () => Builder(
              builder: (ctx) => Scaffold(
                body: TextButton(
                  onPressed: () async =>
                      _resultado = await CardEnrollmentPage.open(ctx),
                  child: const Text('inscribir'),
                ),
              ),
            ),
        interact: false,
        role: 'usuario',
        setup: (b) => _oneclick(b),
        script: (t) async {
          await _pasos(t, 2);
          await _tap(t, find.text('inscribir'));
          await _tap(t, find.text('Inscribir tarjeta'));
          for (var i = 0; i < 4; i++) {
            await t.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 20)));
            await t.pump(const Duration(seconds: 2));
          }
          await _pasos(t, 3);
        });
    expect(_resultado, isTrue);
  });
}
