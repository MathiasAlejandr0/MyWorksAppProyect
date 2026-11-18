import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/testing_feedback_store.dart';
import 'package:myworksapp/features/user/presentation/widgets/testing_feedback_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la encuesta de testing se abre, valida y se envía', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TestingFeedbackDraft? saved;
    Future<void>? pending;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                pending = TestingFeedbackSheet.show(
                  context,
                  onSubmit: (draft) async {
                    saved = draft;
                  },
                );
              },
              child: const Text('Abrir encuesta'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir encuesta'));
    await tester.pumpAndSettle();

    expect(find.text('Encuesta de la prueba'), findsOneWidget);
    expect(find.textContaining('1. Creo que me gustaría usar'), findsOneWidget);

    await tester.tap(find.byTooltip('4 de 5'));
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    expect(find.textContaining('llevas 0 de 10'), findsOneWidget);

    final chips = find.widgetWithText(ChoiceChip, '4');
    expect(chips, findsNWidgets(10));
    for (var i = 0; i < 10; i++) {
      await tester.ensureVisible(chips.at(i));
      await tester.tap(chips.at(i));
      await tester.pump();
    }
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await pending;
    await tester.pump();

    expect(saved?.score, 4);
    expect(saved?.sus, List<int>.filled(10, 4));
    expect(saved?.toRpcParams()['p_plataforma'], 'app');
    expect(find.text('Encuesta de la prueba'), findsNothing);
    expect(find.textContaining('Guardamos tu encuesta'), findsOneWidget);
  });

  test('puntaje SUS con la fórmula estándar', () {
    expect(TestingSurvey.susScore([5, 1, 5, 1, 5, 1, 5, 1, 5, 1]), 100);
    expect(TestingSurvey.susScore(List<int>.filled(10, 3)), 50);
    expect(TestingSurvey.susScore([4, 2, 4, 2, 4, 2, 4, 2, 4, 2]), 75);
    expect(TestingSurvey.susScore([5, 1]), isNull);
  });

  test('sin red queda una copia en el teléfono', () async {
    SharedPreferences.setMockInitialValues({});
    await TestingFeedbackStore.saveLocal(
      const TestingFeedbackDraft(
        score: 5,
        worked: 'Agendar fue claro',
        improve: 'Faltan más gasfíteres en el mapa',
        sus: [5, 1, 5, 1, 5, 1, 5, 1, 5, 1],
      ),
    );
    final rows = await TestingFeedbackStore.readAll();
    expect(rows, hasLength(1));
    expect(rows.single['score'], 5);
    expect(rows.single['sus'], hasLength(10));
  });
}
