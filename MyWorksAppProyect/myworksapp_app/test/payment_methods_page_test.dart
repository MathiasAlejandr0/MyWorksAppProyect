import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/payments/presentation/pages/payment_methods_page.dart';

void main() {
  test('el nombre muestra tipo y últimos 4', () {
    expect(savedCardLabel('Visa', '4242'), 'Visa •••• 4242');
    expect(savedCardLabel('', ''), 'Tarjeta');
  });

  testWidgets('con tarjeta deja agregar otra o eliminarla', (tester) async {
    _tallView(tester);
    var added = 0;
    var removed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentMethodsBody(
          loading: false,
          busy: false,
          cardLabel: 'Visa •••• 4242',
          onAdd: () => added++,
          onRemove: () => removed++,
        ),
      ),
    );

    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(find.text('Agregar otra'), findsOneWidget);
    expect(find.text('Eliminar tarjeta'), findsOneWidget);

    await tester.tap(find.text('Agregar otra'));
    await tester.tap(find.text('Eliminar tarjeta'));
    await tester.pump();
    expect(added, 1);
    expect(removed, 1);
  });

  testWidgets('sin tarjeta solo ofrece agregar', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentMethodsBody(
          loading: false,
          busy: false,
          cardLabel: null,
          onAdd: () {},
        ),
      ),
    );

    expect(find.text('No tienes una tarjeta guardada.'), findsOneWidget);
    expect(find.text('Agregar tarjeta'), findsOneWidget);
    expect(find.text('Eliminar tarjeta'), findsNothing);
  });
}

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
