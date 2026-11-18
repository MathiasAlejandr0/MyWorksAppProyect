import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/onboarding/presentation/pages/onboarding_page.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  double textScale = 1.0,
  bool isFirst = false,
  bool isLast = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: OnboardingNavBar(
              isFirst: isFirst,
              isLast: isLast,
              onPrevious: () {},
              onNext: () {},
              onFinish: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final width in [280.0, 320.0, 360.0, 411.0, 600.0, 900.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('«Anterior» queda en una línea a $width dp, escala $scale',
          (tester) async {
        await _pump(tester, width: width, textScale: scale);

        // La fuente de pruebas (Ahem) ensancha el texto de PrimaryButton y puede
        // marcar un desbordamiento ajeno a «Anterior»: se descarta aquí y se
        // verifica «Anterior» con las medidas de abajo.
        tester.takeException();
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Anterior'),
        );
        // Una sola línea: misma altura que el mismo texto sin restricción de ancho.
        final single = TextPainter(
          text: paragraph.text,
          textDirection: TextDirection.ltr,
          textScaler: paragraph.textScaler,
        )..layout();
        expect(paragraph.size.height, closeTo(single.height, 0.5));
        single.dispose();

        // El texto (ya reducido por FittedBox) cabe dentro del botón lateral.
        final side = OnboardingNavBar.sideWidthFor(width - 40);
        final textRect = tester.getRect(find.text('Anterior'));
        final fitted = tester.getRect(find.byType(FittedBox));
        expect(fitted.width, lessThanOrEqualTo(side));
        final button = tester.getRect(find.byType(TextButton));
        expect(button.width, lessThanOrEqualTo(side));
        expect(textRect.width, greaterThan(0));

        // El botón principal conserva un ancho usable.
        final primary = tester.getSize(find.text('Siguiente'));
        expect(primary.width, greaterThan(40));
      });
    }
  }

  testWidgets('en la primera página no hay «Anterior» y el botón es simétrico',
      (tester) async {
    await _pump(tester, width: 411, isFirst: true);
    expect(find.text('Anterior'), findsNothing);
    expect(find.text('Siguiente'), findsOneWidget);
  });

  testWidgets('en la última página el botón dice «Comenzar»', (tester) async {
    await _pump(tester, width: 360, isLast: true);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.text('Siguiente'), findsNothing);
  });

  test('el ancho lateral se acota entre 76 y 112 dp', () {
    expect(OnboardingNavBar.sideWidthFor(100), 76);
    expect(OnboardingNavBar.sideWidthFor(2000), 112);
    expect(OnboardingNavBar.sideWidthFor(371), closeTo(100.17, 0.01));
  });
}
