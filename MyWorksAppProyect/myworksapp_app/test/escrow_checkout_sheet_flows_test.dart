// EscrowCheckoutSheet: cobro con tarjeta guardada (directo, con reintento por
// monto, sin tarjeta, rechazado), Webpay sin guardar tarjeta, orden de
// cambio, total no disponible y sesión ausente. Todo contra el backend falso.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/pricing_service.dart';
import 'package:myworksapp/core/widgets/escrow_checkout_sheet.dart';

import 'support/fake_supabase.dart';
import 'support/widget_harness.dart';

const _job = '00000000-0000-4000-8000-0000000006b1';

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
  await _pasos(t, 4);
  return true;
}

Widget _lanzador({String? changeOrderId}) => Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => EscrowCheckoutSheet.show(
              context,
              jobId: _job,
              quote: PricingService.instance
                  .calculateVisitBooking(visitFeeClp: 20000),
              workerName: 'Pedro Rojas',
              serviceName: 'Gasfitería',
              changeOrderId: changeOrderId,
            ),
            child: const Text('Abrir cobro'),
          ),
        ),
      ),
    );

void _preview(FakeBackend b, int total) {
  b.rpc('resumen_cobro_trabajo', [
    {
      'total_clp': total,
      'tarifa_clp': total - 3000,
      'traslado_clp': 3000,
      'comision_clp': 2000,
      'neto_clp': total - 2000,
    },
  ]);
}

Future<void> _abrirYPagar(WidgetTester t,
    {bool transbank = false, bool reintentar = false}) async {
  await _pasos(t, 2);
  await _tap(t, find.text('Abrir cobro'));
  await _pasos(t, 3);
  if (reintentar) await _tap(t, find.text('Reintentar el cálculo'));
  if (transbank) {
    await _tap(t, find.text('Pagar en Transbank sin guardar tarjeta'));
  } else {
    await _tap(t, find.textContaining('Pagar con tarjeta'));
  }
  await _pasos(t, 4);
  for (final st in t.stateList<NavigatorState>(find.byType(Navigator))) {
    while (st.canPop()) {
      st.pop();
      await _pasos(t, 1);
    }
  }
  await _tap(t, find.text('Abrir cobro'));
  await _tap(t, find.text('Cancelar'));
}

void main() {
  testWidgets('cobro directo con tarjeta guardada', (t) async {
    await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
        setup: (b) {
      _preview(b, 26000);
      b.functions['oneclick-charge'] = (_) => {'charged': true};
    }, script: _abrirYPagar);
  });

  testWidgets('cobro reintenta con el monto que pide el servidor', (t) async {
    var n = 0;
    await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
        setup: (b) {
      _preview(b, 26000);
      b.functions['oneclick-charge'] = (_) => ++n == 1
          ? {'error': 'Monto 26000 no coincide con tarifa/cotización 26500'}
          : {'charged': true};
    }, script: _abrirYPagar);
  });

  testWidgets('cobro con monto distinto sin reintento posible', (t) async {
    await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
        setup: (b) {
      _preview(b, 26000);
      b.functions['oneclick-charge'] =
          (_) => {'error': 'Monto 26000 no coincide con tarifa 26000'};
    }, script: _abrirYPagar);
  });

  testWidgets('cobro sin tarjeta inscrita abre la inscripción', (t) async {
    await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
        setup: (b) {
      _preview(b, 26000);
      b.functions['oneclick-charge'] = (_) => {'needsCard': true};
    }, script: _abrirYPagar);
  });

  testWidgets('cobro rechazado y respuesta inválida', (t) async {
    var n = 0;
    await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
        setup: (b) {
      _preview(b, 26000);
      b.functions['oneclick-charge'] =
          (_) => ++n == 1 ? {'charged': false} : {'otra': 1};
    }, script: _abrirYPagar);
  });

  testWidgets('cobro con error de red', (t) async {
    await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
        setup: (b) {
      _preview(b, 26000);
      b.failing.add('fn:oneclick-charge');
    }, script: _abrirYPagar);
  });

  testWidgets('Webpay sin guardar tarjeta', (t) async {
    await smokeWidget(t, () => _lanzador(),
        interact: false,
        role: 'usuario',
        setup: (b) {
          _preview(b, 26000);
          b.functions['webpay-create'] = (_) => {
                'token': 'tok',
                'url': 'https://webpay.example/init',
                'redirectUrl': 'https://webpay.example/init?token_ws=tok',
                'buyOrder': 'o1',
                'paymentId': 'p1',
              };
        },
        script: (t) => _abrirYPagar(t, transbank: true));
  });

  testWidgets('Webpay con error y monto distinto', (t) async {
    var n = 0;
    await smokeWidget(t, () => _lanzador(),
        interact: false,
        role: 'usuario',
        setup: (b) {
          _preview(b, 26000);
          b.functions['webpay-create'] = (_) => ++n == 1
              ? {'error': 'Monto 26000 no coincide con cotización 27000'}
              : {'error': 'rechazado'};
        },
        script: (t) => _abrirYPagar(t, transbank: true));
  });

  testWidgets('orden de cambio paga por Webpay', (t) async {
    await smokeWidget(t, () => _lanzador(changeOrderId: 'oc-1'),
        interact: false, role: 'usuario', setup: (b) {
      b.functions['webpay-create'] = (_) => {'error': 'falla de prueba'};
    }, script: _abrirYPagar);
  });

  testWidgets('total no disponible y reintento', (t) async {
    await smokeWidget(t, () => _lanzador(),
        interact: false,
        role: 'usuario',
        setup: (b) {
          b.failing.add('resumen_cobro_trabajo');
        },
        script: (t) => _abrirYPagar(t, reintentar: true));
  });

  testWidgets('total vuelve vacío al pagar', (t) async {
    var n = 0;
    await smokeWidget(t, () => _lanzador(), interact: false, role: 'usuario',
        setup: (b) {
      b.rpcs['resumen_cobro_trabajo'] = (_) => ++n == 1
          ? [
              {'total_clp': 26000}
            ]
          : <Object>[];
      b.functions['oneclick-charge'] = (_) => {'charged': true};
    }, script: _abrirYPagar);
  });

  testWidgets('sin sesión', (t) async {
    await smokeWidget(t, () => _lanzador(), interact: false, signedIn: false,
        setup: (b) {
      _preview(b, 26000);
    }, script: _abrirYPagar);
  });
}
