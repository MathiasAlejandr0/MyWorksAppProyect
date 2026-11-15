import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/testing_feedback_store.dart';
import 'package:myworksapp/features/user/presentation/widgets/testing_feedback_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('el formulario de feedback se abre, valida y se cierra', (tester) async {
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
              child: const Text('Abrir feedback'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Feedback de la prueba'), findsOneWidget);
    expect(find.text('Qué mejorarías'), findsOneWidget);

    await tester.tap(find.byTooltip('4 de 5'));
    await tester.enterText(find.widgetWithText(TextField, 'Qué mejorarías'), 'El mapa');
    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(find.textContaining('mínimo 8 caracteres'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Qué mejorarías'),
      'El mapa de Puerto Montt se entiende bien.',
    );
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await pending;
    await tester.pump();

    expect(saved?.score, 4);
    expect(find.text('Feedback de la prueba'), findsNothing);
    expect(find.textContaining('Guardamos tu feedback'), findsOneWidget);
  });

  test('el feedback queda guardado en el teléfono', () async {
    SharedPreferences.setMockInitialValues({});
    await TestingFeedbackStore.save(
      const TestingFeedbackDraft(
        score: 5,
        worked: 'Agendar fue claro',
        improve: 'Faltan más gasfíteres en el mapa',
      ),
    );
    final rows = await TestingFeedbackStore.readAll();
    expect(rows, hasLength(1));
    expect(rows.single['score'], 5);
    expect(rows.single['improve'], 'Faltan más gasfíteres en el mapa');
  });
}
