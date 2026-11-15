import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/design_system/service_pin_dialog.dart';

void main() {
  testWidgets('confirmar devuelve los 4 dígitos y muestra el error del servidor',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? pin;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                pin = await ServicePinDialog.show(
                  context,
                  serverError: 'PIN incorrecto. Te quedan 4 intentos.',
                );
              },
              child: const Text('abrir'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('PIN incorrecto. Te quedan 4 intentos.'), findsOneWidget);
    expect(find.text('Confirmar PIN'), findsOneWidget);

    for (final digit in ['4', '8', '2', '9']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.tap(find.text('Confirmar PIN'));
    await tester.pumpAndSettle();

    expect(pin, '4829');
  });
}
