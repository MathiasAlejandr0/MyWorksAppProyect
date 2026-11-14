import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/features/ratings/domain/client_rating_label.dart';
import 'package:myworksapp/features/ratings/presentation/widgets/client_rating_badge.dart';

void main() {
  test('sin notas dice Cliente nuevo y con notas muestra promedio y cantidad',
      () {
    expect(clientRatingLabel(count: 0), 'Cliente nuevo');
    expect(clientRatingLabel(average: null, count: 2), 'Cliente nuevo');
    expect(
      clientRatingLabel(average: 4.8, count: 3),
      '4.8 · 3 calificaciones',
    );
    expect(
      clientRatingLabel(average: 5, count: 1),
      '5.0 · 1 calificación',
    );
    expect(
      clientRatingLabel(count: 0, known: false),
      'Reputación no disponible',
    );
  });

  testWidgets('la tarjeta de decisión muestra Cliente nuevo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClientRatingBadge(label: 'Cliente nuevo'),
        ),
      ),
    );
    expect(find.text('Cliente nuevo'), findsOneWidget);
  });
}
