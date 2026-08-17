import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/design_system/app_breakpoints.dart';

void main() {
  testWidgets('AppBreakpoints usa 2 columnas en teléfono', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final columns = AppBreakpoints.gridColumns(context);
            return Text('cols:$columns');
          },
        ),
      ),
    );

    expect(find.text('cols:2'), findsOneWidget);
  });

  testWidgets('AppBreakpoints usa 3 columnas en tablet', (tester) async {
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final columns = AppBreakpoints.gridColumns(context);
            return Text('cols:$columns');
          },
        ),
      ),
    );

    expect(find.text('cols:3'), findsOneWidget);
  });
}
