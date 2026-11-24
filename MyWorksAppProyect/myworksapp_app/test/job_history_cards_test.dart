import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/job_history_cards.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/job_status_timeline.dart';

void main() {
  test('la carta de avance aparece desde que el pago queda retenido', () {
    expect(jobHistoryPhaseLabels, hasLength(jobTimelineSteps.length));

    expect(jobHistoryIsLive(AppConstants.jobStatusPending), isTrue);
    expect(jobHistoryIsLive(AppConstants.jobStatusAccepted), isTrue);
    expect(jobHistoryIsLive(AppConstants.jobStatusEnRoute), isTrue);
    expect(jobHistoryIsLive(AppConstants.jobStatusInProgress), isTrue);
    expect(
      jobHistoryIsLive(PricingConstants.jobAwaitingClientApproval),
      isTrue,
    );
    expect(jobHistoryIsLive(PricingConstants.jobPausedChangeOrder), isTrue);

    expect(jobHistoryIsLive(PricingConstants.jobAwaitingPayment), isFalse);
    expect(jobHistoryIsLive(PricingConstants.jobAwaitingQuotes), isFalse);
    expect(jobHistoryIsLive(AppConstants.jobStatusCompleted), isFalse);
    expect(jobHistoryIsLive(AppConstants.jobStatusCancelled), isFalse);

    expect(
      jobHistoryPhaseIndex(PricingConstants.jobAwaitingClientApproval),
      4,
    );
    expect(
      jobHistoryPhaseIndex(PricingConstants.jobPausedChangeOrder),
      jobTimelineIndex(AppConstants.jobStatusInProgress),
    );
  });

  testWidgets('el trabajo abierto muestra las fases en horizontal', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: JobHistoryLiveCard(
            title: 'Cambio de cableado lan en mi oficina',
            address: 'FR3X+WV, Panitao, Los Lagos',
            dateLabel: '20/11/2026',
            status: PricingConstants.jobAwaitingClientApproval,
            onTap: () => opened++,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Pago retenido'), findsOneWidget);
    expect(find.text('Espera'), findsOneWidget);
    expect(find.text('Acepta'), findsOneWidget);
    expect(find.text('Camino'), findsOneWidget);
    expect(find.text('Curso'), findsOneWidget);
    expect(find.text('Conforme'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);
    expect(find.text('Esperando conformidad'), findsOneWidget);
    expect(find.text('Siguiente: Completado'), findsOneWidget);
    expect(find.text('5/6'), findsOneWidget);

    await tester.tap(find.text('Pago retenido'));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('un cobro extra no anuncia la fase siguiente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobHistoryLiveCard(
            title: 'Instalación',
            address: 'Panitao',
            dateLabel: '20/11/2026',
            status: PricingConstants.jobPausedChangeOrder,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Cobro extra pendiente'), findsOneWidget);
    expect(find.textContaining('Siguiente:'), findsNothing);
    expect(find.text('4/6'), findsOneWidget);
  });

  testWidgets('el trabajo completado usa el sello y no el recorrido', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: JobHistoryCompletedCard(
            title: 'formatea 3 pcs',
            address: 'FR3X+WV, Panitao, Los Lagos',
            dateLabel: '20/11/2026',
            paymentStatus: PricingConstants.paymentReleased,
            onTap: () => opened++,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('COMPLETADO'), findsOneWidget);
    expect(find.text('Pago liberado'), findsOneWidget);
    expect(find.text('formatea 3 pcs'), findsOneWidget);
    expect(find.text('Espera'), findsNothing);
    expect(find.text('Pago retenido'), findsNothing);

    await tester.tap(find.text('COMPLETADO'));
    await tester.pump();
    expect(opened, 1);
  });
}
