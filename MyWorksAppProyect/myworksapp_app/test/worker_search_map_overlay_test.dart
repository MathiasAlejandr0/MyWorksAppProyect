import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/user/presentation/widgets/worker_search_map.dart';

void main() {
  for (final width in [280.0, 320.0, 360.0, 411.0, 600.0, 900.0]) {
    testWidgets('el contador y la leyenda del mapa no se solapan a $width dp',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  right: 56,
                  child: WorkerMapOverlayHeader(
                    text: '3 en el mapa · Armado de muebles',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      // La fuente de pruebas (Ahem) es más ancha que Roboto: se descartan
      // desbordes de texto y se comprueba la geometría.
      tester.takeException();

      final materials = find.descendant(
        of: find.byType(WorkerMapOverlayHeader),
        matching: find.byType(Material),
      );
      expect(materials, findsNWidgets(2));
      final chip = tester.getRect(materials.first);
      final legend = tester.getRect(materials.last);
      expect(chip.overlaps(legend), isFalse,
          reason: 'chip $chip vs leyenda $legend');
      expect(legend.top, greaterThanOrEqualTo(chip.bottom));
      expect(chip.right, lessThanOrEqualTo(width - 56));
      expect(legend.right, lessThanOrEqualTo(width - 56));
      expect(find.text('3 en el mapa · Armado de muebles'), findsOneWidget);
      expect(find.text('Profesionales'), findsOneWidget);
    });
  }
}
