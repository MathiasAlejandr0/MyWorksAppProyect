import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/theme/app_theme.dart';
import 'package:myworksapp/features/user/presentation/widgets/worker_list_chrome.dart';

Widget _host(Widget child, {bool dark = true, double width = 411}) {
  return MaterialApp(
    theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  for (final dark in [true, false]) {
    for (final width in [320.0, 411.0, 800.0]) {
      testWidgets(
          'WorkerListAddressRow no colapsa el campo ni desborda (${dark ? 'oscuro' : 'claro'}, $width dp)',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            WorkerListAddressRow(
              addressController: TextEditingController(),
              onSearch: () {},
              onUseGps: () {},
              locatingAddress: false,
              locatingGps: false,
              hasFix: true,
            ),
            dark: dark,
            width: width,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Buscar'), findsOneWidget);
        expect(find.text('Ubicación lista'), findsOneWidget);
        // El campo conserva un ancho usable (antes quedaba en ~16 dp).
        expect(tester.getSize(find.byType(TextField)).width, greaterThan(120));
        // El botón «Buscar» tampoco ocupa todo el ancho.
        expect(tester.getSize(find.byType(FilledButton)).width, lessThan(160));
      });
    }
  }

  testWidgets('el chip de ubicación cambia según el estado', (tester) async {
    var taps = 0;
    Future<void> show({required bool locating, required bool ready}) async {
      await tester.pumpWidget(
        _host(
          WorkerListLocationChip(
            locating: locating,
            ready: ready,
            onPressed: locating ? null : () => taps++,
          ),
        ),
      );
    }

    await show(locating: false, ready: false);
    expect(find.text('Usar GPS'), findsOneWidget);
    await tester.tap(find.text('Usar GPS'));
    expect(taps, 1);

    await show(locating: false, ready: true);
    expect(find.text('Ubicación lista'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await show(locating: true, ready: true);
    expect(find.text('Leyendo GPS…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('«Disponible ahora» muestra la tarjeta y alterna el valor',
      (tester) async {
    var value = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => WorkerListAvailableNowTile(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    expect(find.text('Disponible ahora'), findsOneWidget);
    expect(
      find.text('Respeta el horario semanal si el profesional lo activó'),
      findsOneWidget,
    );
    expect(find.byType(DecoratedBox), findsWidgets);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(value, isTrue);
  });
}
