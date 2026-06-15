import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:myworksapp/core/design_system/app_breakpoints.dart';

void main() {
  testWidgets('AppBreakpoints detecta tablet desde 600dp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 1280)),
          child: Builder(
            builder: (context) {
              expect(AppBreakpoints.isTablet(context), isTrue);
              expect(AppBreakpoints.gridColumns(context), 3);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });

  testWidgets('AppBreakpoints mantiene phone en pantallas pequeñas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(
            builder: (context) {
              expect(AppBreakpoints.isTablet(context), isFalse);
              expect(AppBreakpoints.gridColumns(context), 2);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });
}
