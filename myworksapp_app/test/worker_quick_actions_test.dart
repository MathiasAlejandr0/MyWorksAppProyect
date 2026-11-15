import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/worker/presentation/widgets/worker_quick_actions_row.dart';

void main() {
  testWidgets('historial e ingresos abren destinos reales', (tester) async {
    var history = 0;
    var earnings = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkerQuickActionsRow(
            onNewJob: () {},
            onCalendar: () {},
            onHistory: () => history++,
            onEarnings: () => earnings++,
          ),
        ),
      ),
    );

    expect(find.text('Mapa de trabajos'), findsNothing);
    expect(find.text('Mis facturas'), findsNothing);

    await tester.tap(find.text('Historial'));
    await tester.tap(find.text('Ingresos'));
    await tester.pump();

    expect(history, 1);
    expect(earnings, 1);
  });
}
