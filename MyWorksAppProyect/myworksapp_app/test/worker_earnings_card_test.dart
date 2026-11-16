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
            expect(find.textContaining('vs. mes anterior'), findsNothing);
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

  Future<void> pumpGrowth(
    WidgetTester tester,
    WorkerEarningsSnapshot snapshot,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: WorkerEarningsCard(data: snapshot, onViewDetails: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('sin mes anterior no muestra un porcentaje', (tester) async {
    await pumpGrowth(
      tester,
      const WorkerEarningsSnapshot(
        escrowClp: 0,
        releasedClp: 160000,
        pendingClp: 0,
        paymentCount: 5,
      ),
    );
    expect(find.textContaining('vs. mes anterior'), findsNothing);
    expect(find.text('Se mostrarán al confirmar pagos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el porcentaje real cuando hay mes anterior', (tester) async {
    await pumpGrowth(
      tester,
      const WorkerEarningsSnapshot(
        escrowClp: 0,
        releasedClp: 256000,
        pendingClp: 0,
        paymentCount: 8,
        growthPercent: 67,
      ),
    );
    expect(find.text('67% vs. mes anterior'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('una baja real se muestra hacia abajo', (tester) async {
    await pumpGrowth(
      tester,
      const WorkerEarningsSnapshot(
        escrowClp: 0,
        releasedClp: 80000,
        pendingClp: 0,
        paymentCount: 2,
        growthPercent: -20,
      ),
    );
    expect(find.text('-20% vs. mes anterior'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
  });

  testWidgets('sin pagos explica que aparecerán al confirmar', (tester) async {
    await pumpGrowth(tester, WorkerEarningsSnapshot.zero);
    expect(find.text('Se mostrarán al confirmar pagos'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}
