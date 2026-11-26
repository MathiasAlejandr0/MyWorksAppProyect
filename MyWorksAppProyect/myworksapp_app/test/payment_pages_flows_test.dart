// PaymentMethodsPage y PaymentScreen contra `oneclick-charge` y
// `webpay-create` simulados: leer, reemplazar y eliminar la tarjeta; cobrar
// con tarjeta (directo, inscripción previa, rechazo) y Webpay con errores.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/payments/presentation/pages/payment_methods_page.dart';
import 'package:myworksapp/features/payments/presentation/pages/payment_screen.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

Future<void> _pasos(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<bool> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) return false;
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _pasos(t, 3);
  return true;
}

/// Respuestas de `oneclick-charge` por acción.
void _oneclick(
  FakeBackend b, {
  bool inscrita = true,
  Object? cobro = const {'charged': true},
  Object? inscribir = const {'enrolled': true},
  Object? quitar = const {'ok': true},
}) {
  var cobros = 0;
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
        return quitar;
      default:
        cobros++;
        if (cobro is List) return cobro[(cobros - 1) % cobro.length];
        return cobro;
    }
  };
}

Future<void> _metodos(WidgetTester t) async {
  await _pasos(t, 4);
  await _tap(t, find.text('Reintentar'));
  // Reemplazar: cancelar y luego confirmar.
  if (await _tap(t, find.text('Agregar otra'))) {
    await _tap(t, find.text('Cancelar'));
    await _tap(t, find.text('Agregar otra'));
    await _tap(t, find.text('Reemplazar'));
    await _pasos(t, 2);
    await _tap(t, find.text('Inscribir tarjeta'));
    await _pasos(t, 2);
    await _tap(t, find.text('Ahora no'));
    await _pasos(t, 3);
  } else {
    await _tap(t, find.text('Agregar tarjeta'));
    await _tap(t, find.text('Inscribir tarjeta'));
    await _pasos(t, 3);
    await _tap(t, find.text('Ahora no'));
  }
  // Eliminar: cancelar y luego confirmar.
  if (await _tap(t, find.text('Eliminar tarjeta'))) {
    await _tap(t, find.text('Cancelar'));
    await _tap(t, find.text('Eliminar tarjeta'));
    await _tap(t, find.text('Eliminar'));
    await _pasos(t, 3);
  }
}

Widget _lanzador() => Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => PaymentScreen.open(
              context,
              jobId: 'job-pago-1',
              amount: 25000,
              serviceName: 'Gasfitería',
              specialistName: 'Pedro Rojas',
            ),
            child: const Text('Abrir pago'),
          ),
        ),
      ),
    );

Future<void> _pagar(WidgetTester t, {bool transbank = false}) async {
  await _pasos(t, 2);
  await _tap(t, find.text('Abrir pago'));
  await _pasos(t, 2);
  if (transbank) {
    await _tap(t, find.text('Pagar en Transbank sin guardar tarjeta'));
  } else {
    await _tap(t, find.text('Confirmar con tarjeta'));
  }
  await _pasos(t, 3);
  // Si se abrió la inscripción, inscribir.
  if (await _tap(t, find.text('Inscribir tarjeta'))) {
    await _pasos(t, 3);
    await _tap(t, find.text('Ahora no'));
  }
  for (final st in t.stateList<NavigatorState>(find.byType(Navigator))) {
    while (st.canPop()) {
      st.pop();
      await _pasos(t, 1);
    }
  }
}

void main() {
  group('PaymentMethodsPage', () {
    testWidgets('con tarjeta: reemplazar y eliminar', (t) async {
      await smokeWidget(t, () => const PaymentMethodsPage(),
          interact: false,
          role: 'usuario',
          setup: (b) => _oneclick(b),
          script: _metodos);
    });

    testWidgets('reemplazo abandonado y falla al eliminar', (t) async {
      await smokeWidget(t, () => const PaymentMethodsPage(),
          interact: false, role: 'usuario', setup: (b) {
        _oneclick(b,
            inscribir: {'url': 'https://webpay.example/x', 'token': 'tk'},
            quitar: {'error': 'no se pudo'});
      }, script: _metodos);
    });

    testWidgets('sin tarjeta', (t) async {
      await smokeWidget(t, () => const PaymentMethodsPage(),
          interact: false,
          role: 'usuario',
          setup: (b) => _oneclick(b, inscrita: false),
          script: _metodos);
    });

    testWidgets('error al leer la tarjeta', (t) async {
      await smokeWidget(t, () => const PaymentMethodsPage(),
          interact: false, role: 'usuario', setup: (b) {
        b.functions['oneclick-charge'] = (_) => {'error': 'servicio caído'};
      }, script: _metodos);
    });

    testWidgets('falla de red al leer la tarjeta', (t) async {
      await smokeWidget(t, () => const PaymentMethodsPage(),
          interact: false, role: 'usuario', setup: (b) {
        b.failing.add('fn:oneclick-charge');
      }, script: _metodos);
    });
  });

  group('PaymentScreen', () {
    testWidgets('cobro directo con tarjeta', (t) async {
      await smokeWidget(t, () => _lanzador(),
          interact: false,
          role: 'usuario',
          setup: (b) => _oneclick(b),
          script: _pagar);
    });

    testWidgets('sin tarjeta: inscribe y cobra', (t) async {
      await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
          setup: (b) {
        _oneclick(b, cobro: [
          {'needsCard': true},
          {'charged': true},
        ]);
      }, script: _pagar);
    });

    testWidgets('sin tarjeta: inscribe y el cobro vuelve a fallar', (t) async {
      await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
          setup: (b) {
        _oneclick(b, cobro: [
          {'needsCard': true},
          {'needsCard': true},
        ]);
      }, script: _pagar);
    });

    testWidgets('sin tarjeta y no inscribe', (t) async {
      await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
          setup: (b) {
        _oneclick(b,
            cobro: {'needsCard': true},
            inscribir: {'url': 'https://webpay.example/x', 'token': 'tk'});
      }, script: _pagar);
    });

    testWidgets('respuesta sin cobro, error de negocio y de red', (t) async {
      for (final r in [
        {'charged': false},
        {'error': 'tarjeta rechazada'},
      ]) {
        await smokeWidget(t, () => _lanzador(),
            interact: false,
            role: 'usuario',
            setup: (b) => _oneclick(b, cobro: r),
            script: _pagar);
      }
      await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
          setup: (b) {
        b.failing.add('fn:oneclick-charge');
      }, script: _pagar);
    });

    testWidgets('Webpay sin guardar tarjeta: abre, error y falla', (t) async {
      for (final r in <Object>[
        {
          'token': 'tok',
          'url': 'https://webpay.example/init',
          'paymentId': 'p1',
        },
        {'error': 'monto inválido'},
      ]) {
        await smokeWidget(t, () => _lanzador(),
            interact: false,
            role: 'usuario',
            setup: (b) {
              b.functions['webpay-create'] = (_) => r;
            },
            script: (t) => _pagar(t, transbank: true));
      }
      await smokeWidget(t, () => _lanzador(),
          interact: false,
          role: 'usuario',
          setup: (b) {
            b.functions['webpay-create'] = (_) => 'no-es-mapa';
          },
          script: (t) => _pagar(t, transbank: true));
    });
  });
}
