import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/user/presentation/widgets/in_progress_job_card.dart';

void main() {
  testWidgets('muestra el avance del trabajo en curso y abre el detalle',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InProgressJobCard(
            serviceName: 'Soporte técnico',
            description: 'formatea 3 pcs',
            address: 'Puerto Montt',
            status: 'en_curso',
            onOpen: () => opened++,
          ),
        ),
      ),
    );

    expect(find.text('Trabajo en curso'), findsOneWidget);
    expect(find.text('Soporte técnico'), findsOneWidget);
    expect(find.text('formatea 3 pcs'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('Paso 4 de 6 · En curso'), findsOneWidget);
    expect(find.text('Siguiente: Esperando conformidad'), findsOneWidget);

    await tester.tap(find.text('Ver trabajo'));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('con disputa no anuncia el paso siguiente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InProgressJobCard(
            serviceName: 'Gasfitería',
            description: 'Llave',
            address: 'Puerto Montt',
            status: 'en_curso',
            pausedByDispute: true,
            onOpen: () {},
          ),
        ),
      ),
    );

    expect(find.text('En pausa por una disputa'), findsWidgets);
    expect(find.textContaining('Siguiente:'), findsNothing);
  });

  testWidgets('la conformidad sigue visible en el inicio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InProgressJobCard(
            serviceName: 'Gasfitería',
            description: 'Llave',
            address: 'Puerto Montt',
            status: 'esperando_aprobacion_cliente',
            onOpen: () {},
          ),
        ),
      ),
    );

    expect(find.text('Falta tu conformidad'), findsOneWidget);
    expect(find.text('Siguiente: Completado'), findsOneWidget);
  });
}
