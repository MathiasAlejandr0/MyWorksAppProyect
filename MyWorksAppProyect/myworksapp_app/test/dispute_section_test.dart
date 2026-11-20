import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/dispute_section.dart';

void main() {
  testWidgets('el motivo elegido se envía con el mismo código', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? reason;
    String? description;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: DisputeSection(
            dispute: null,
            canOpenDispute: true,
            isParticipant: true,
            onOpenDispute: (value, detail) async {
              reason = value;
              description = detail;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir disputa'));
    await tester.pumpAndSettle();

    expect(find.text('Calidad del trabajo'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    await tester.tap(find.text('Calidad del trabajo'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Quedó mal el trabajo');
    await tester.tap(find.text('Enviar disputa'));
    await tester.pumpAndSettle();

    expect(reason, AppConstants.disputeReasonQuality);
    expect(description, 'Quedó mal el trabajo');
  });

  testWidgets('proponer un acuerdo conserva el tipo', (tester) async {
    String? proposed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DisputeSection(
              dispute: null,
              canOpenDispute: true,
              isParticipant: true,
              canNegotiate: true,
              onOpenDispute: (_, __) async {},
              onProposeAgreement: (type) async {
                proposed = type;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rehacer'));
    await tester.pump();
    expect(proposed, 'rehacer');
  });
}
