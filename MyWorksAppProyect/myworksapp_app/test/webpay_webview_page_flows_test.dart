// WebpayWebViewPage con un WebViewPlatform falso: carga por URL y por HTML,
// retorno aprobado y rechazado por cada vía (pedido de navegación, fin de
// página, cambio de URL, error), sondeo del resultado, cancelar y Android.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/webpay_webview_page.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'support/fake_webview.dart';

const _ok = 'myworksapp://pago?pago=ok';
const _fail = 'myworksapp://pago?pago=fail';

late FakeWebViewPlatform _web;
bool? _resultado;

Future<void> _abrir(WidgetTester t,
    {String? url = 'https://webpay3gint.transbank.cl/x',
    String? html,
    Future<bool?> Function()? watch}) async {
  _resultado = null;
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (ctx) => Scaffold(
        body: FilledButton(
          onPressed: () async {
            _resultado = await WebpayWebViewPage.open(ctx,
                paymentUrl: url, html: html, watchOutcome: watch);
          },
          child: const Text('pagar'),
        ),
      ),
    ),
  ));
  await t.tap(find.text('pagar'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

Future<void> _cerrar(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 500));
}

void main() {
  setUp(() => _web = FakeWebViewPlatform.install());

  testWidgets('carga la URL y el pedido de navegación aprobado cierra',
      (t) async {
    await _abrir(t);
    expect(_web.controller!.loaded.single, contains('transbank'));
    final d = _web.delegate!;
    d.onPageStarted!('https://webpay3gint.transbank.cl/x');
    await t.pump();
    d.onPageFinished!('https://webpay3gint.transbank.cl/x');
    await t.pump();
    expect(await d.navigate('https://webpay3gint.transbank.cl/y'),
        NavigationDecision.navigate);
    expect(await d.navigate(_ok), NavigationDecision.prevent);
    await _cerrar(t);
    expect(_resultado, isTrue);
  });

  testWidgets('fin de página en la vuelta rechazada', (t) async {
    await _abrir(t);
    _web.delegate!.onPageFinished!(_fail);
    await _cerrar(t);
    expect(_resultado, isFalse);
  });

  testWidgets('cambio de URL y errores', (t) async {
    await _abrir(t);
    final d = _web.delegate!;
    d.onUrlChange!(const UrlChange(url: null));
    d.onUrlChange!(const UrlChange(url: 'https://otra.cl'));
    d.error(_ok, mainFrame: false);
    d.error('https://otra.cl', mainFrame: true);
    await t.pump();
    d.onUrlChange!(const UrlChange(url: _ok));
    await _cerrar(t);
    expect(_resultado, isTrue);
  });

  testWidgets('error del marco principal en la vuelta', (t) async {
    await _abrir(t);
    _web.delegate!.error(_fail);
    await _cerrar(t);
    expect(_resultado, isFalse);
  });

  testWidgets('HTML de Transbank y cancelar', (t) async {
    await _abrir(t, url: null, html: '<form></form>');
    expect(_web.controller!.loaded.single, startsWith('html:'));
    await t.tap(find.byTooltip('Cancelar'));
    await _cerrar(t);
    expect(_resultado, isFalse);
  });

  testWidgets('sin URL ni HTML no carga nada', (t) async {
    await _abrir(t, url: '');
    expect(_web.controller!.loaded, isEmpty);
    await t.tap(find.byTooltip('Cancelar'));
    await _cerrar(t);
  });

  testWidgets('el sondeo cierra cuando el pago queda resuelto', (t) async {
    var vueltas = 0;
    await _abrir(t, watch: () async {
      vueltas++;
      if (vueltas == 1) return null;
      if (vueltas == 2) throw Exception('red');
      return true;
    });
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(seconds: 2));
    }
    await _cerrar(t);
    expect(_resultado, isTrue);
  });

  testWidgets('Android (plataforma de pruebas por defecto) explícito',
      (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _abrir(t);
      expect(find.byKey(const ValueKey('fake-webview')), findsOneWidget);
      await t.tap(find.byTooltip('Cancelar'));
      await _cerrar(t);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('en iOS usa el widget estándar', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _abrir(t);
      expect(find.byKey(const ValueKey('fake-webview')), findsOneWidget);
      await t.tap(find.byTooltip('Cancelar'));
      await _cerrar(t);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
