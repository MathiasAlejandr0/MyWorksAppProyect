import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/providers/service_providers.dart';
import 'package:myworksapp/core/services/payment_service.dart';
import 'package:myworksapp/core/widgets/saved_card_tile.dart';

class _FakePayments extends PaymentService {
  _FakePayments({required this.enrolled});

  bool enrolled;
  int removed = 0;

  @override
  Future<({bool enrolled, String last4, String cardType})> savedCard({
    bool recoverAbandoned = false,
  }) async =>
      (enrolled: enrolled, last4: enrolled ? '6623' : '', cardType: 'Visa');

  @override
  Future<void> removeSavedCard() async {
    removed += 1;
    enrolled = false;
  }
}

Widget _host(_FakePayments payments, Future<void> Function() onRemoved) {
  return ProviderScope(
    overrides: [paymentServiceProvider.overrideWithValue(payments)],
    child: MaterialApp(
      home: Scaffold(body: SavedCardTile(onCardRemoved: onRemoved)),
    ),
  );
}

void main() {
  testWidgets('muestra la tarjeta guardada con sus últimos 4', (tester) async {
    final payments = _FakePayments(enrolled: true);
    await tester.pumpWidget(_host(payments, () async {}));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-card-label')), findsOneWidget);
    expect(find.textContaining('Visa •••• 6623'), findsOneWidget);
    expect(find.text('Cambiar tarjeta'), findsOneWidget);
  });

  testWidgets('no pinta nada si todavía no hay tarjeta', (tester) async {
    final payments = _FakePayments(enrolled: false);
    await tester.pumpWidget(_host(payments, () async {}));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('saved-card-label')), findsNothing);
    expect(find.text('Cambiar tarjeta'), findsNothing);
  });

  testWidgets('cambiar tarjeta la quita y abre la inscripción de otra', (tester) async {
    final payments = _FakePayments(enrolled: true);
    var enrollOpened = 0;
    await tester.pumpWidget(_host(payments, () async => enrollOpened += 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cambiar tarjeta'));
    await tester.pumpAndSettle();

    expect(payments.removed, 1);
    expect(enrollOpened, 1);
    expect(find.byKey(const Key('saved-card-label')), findsNothing);
  });
}
