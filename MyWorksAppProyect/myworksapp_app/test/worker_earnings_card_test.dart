import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/worker_earnings_snapshot.dart';
import 'package:myworksapp/core/theme/app_theme.dart';
import 'package:myworksapp/features/worker/presentation/widgets/worker_earnings_summary.dart';

void main() {
  const data = WorkerEarningsSnapshot(
    escrowClp: 1250000,
    releasedClp: 3480000,
    pendingClp: 0,
    paymentCount: 7,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required ThemeData theme,
    required double width,
    required double textScale,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: WorkerEarningsCard(data: data, onViewDetails: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final themeName in ['light', 'dark']) {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets(
          'Ganancias totales legible ($themeName, ${width.toInt()}px, x$scale)',
          (tester) async {
            await pumpCard(
              tester,
              theme: themeName == 'light'
                  ? AppTheme.lightTheme
                  : AppTheme.darkTheme,
              width: width,
              textScale: scale,
            );

            expect(tester.takeException(), isNull);
            final label = find.text('Ganancias totales');
            expect(label, findsOneWidget);
            // Antes el botón ocupaba todo el ancho y el texto quedaba en una
            // columna de una letra. Debe tener un ancho real.
            expect(tester.getSize(label).width, greaterThan(80));
            expect(tester.getSize(label).height, lessThan(12 * scale * 2));
            expect(find.text('Ver detalles'), findsOneWidget);
            expect(tester.getSize(find.byType(OutlinedButton)).width,
                lessThan(width));
          },
        );
      }
    }
  }
}
