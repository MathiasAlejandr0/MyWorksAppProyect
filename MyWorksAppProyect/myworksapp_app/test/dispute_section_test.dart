import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/dispute_section.dart';

void main() {
  Future<void> pumpOpen(WidgetTester tester, {
    required Future<void> Function(String reason, String? description, String outcome) onOpen,
    VoidCallback? onCancel,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DisputeSection(
              dispute: null,
              canOpenDispute: true,
              isParticipant: true,
              onCancelRequest: onCancel,
              onOpenDispute: onOpen,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('la carta no muestra las opciones hasta abrir la disputa', (tester) async {
    await pumpOpen(tester, onOpen: (_, __, ___) async {}, onCancel: () {});

    expect(find.text('Aceptar entrega'), findsNothing);
    expect(find.text('Rehacer'), findsNothing);
    expect(find.text('Anular'), findsNothing);
    expect(find.text('Abrir disputa'), findsOneWidget);
  });

  testWidgets('elige el desenlace y después el motivo', (tester) async {
    String? reason;
    String? description;
    String? outcome;
    await pumpOpen(
      tester,
      onOpen: (value, detail, chosen) async {
        reason = value;
        description = detail;
        outcome = chosen;
      },
      onCancel: () {},
    );

    await tester.tap(find.text('Abrir disputa'));
    await tester.pumpAndSettle();

    expect(find.text('Aceptar entrega'), findsOneWidget);
    expect(find.text('Rehacer'), findsOneWidget);
    expect(find.text('Anular'), findsOneWidget);
    expect(find.text('Cancelar solicitud'), findsOneWidget);
    expect(find.text('Calidad del trabajo'), findsNothing);

    await tester.tap(find.text('Rehacer'));
    await tester.pumpAndSettle();

    expect(find.text('Elegiste Rehacer. Ahora indica el motivo. El pago sigue retenido hasta cerrar el caso.'), findsOneWidget);
    await tester.tap(find.text('Calidad del trabajo'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Quedó mal el trabajo');
    await tester.tap(find.text('Enviar disputa'));
    await tester.pumpAndSettle();

    expect(reason, AppConstants.disputeReasonQuality);
    expect(description, 'Quedó mal el trabajo');
    expect(outcome, 'rehacer');
  });

  testWidgets('cancelar la solicitud desde el botón no abre la disputa', (tester) async {
    var opened = 0;
    var cancelled = 0;
    await pumpOpen(
      tester,
      onOpen: (_, __, ___) async {
        opened++;
      },
      onCancel: () => cancelled++,
    );

    await tester.tap(find.text('Abrir disputa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();

    expect(cancelled, 1);
    expect(opened, 0);
    expect(find.text('Motivo de la disputa'), findsNothing);
  });
}
