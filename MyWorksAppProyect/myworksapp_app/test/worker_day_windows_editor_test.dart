import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/weekly_schedule.dart';
import 'package:myworksapp/features/worker/presentation/widgets/worker_day_windows_editor.dart';

void main() {
  testWidgets('un día activo muestra inicio, fin y permite otra ventana',
      (tester) async {
    var day = const DayWindow(
      weekday: 1,
      startMinute: 9 * 60,
      endMinute: 18 * 60,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return WorkerDayWindowsEditor(
                name: 'Lunes',
                day: day,
                onChanged: (next) => setState(() => day = next),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
    expect(find.textContaining('09:00, 10:00'), findsOneWidget);

    await tester.tap(find.text('Agregar ventana'));
    await tester.pump();

    expect(find.text('Inicio'), findsNWidgets(2));
    expect(day.windows, hasLength(2));
    expect(day.windows.last.startMinute, 18 * 60);
    expect(overlappingWindowsMessage([day]), isNull);
  });

  testWidgets('activar el día despliega inicio y fin', (tester) async {
    var day = const DayWindow(
      weekday: 7,
      startMinute: 9 * 60,
      endMinute: 13 * 60,
      enabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return WorkerDayWindowsEditor(
                name: 'Domingo',
                day: day,
                onChanged: (next) => setState(() => day = next),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Inicio'), findsNothing);
    expect(find.textContaining('Activa el día'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(day.enabled, isTrue);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('13:00'), findsOneWidget);
  });
}
