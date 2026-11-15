import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/utils/app_text_scaling.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/worker/presentation/widgets/worker_job_card.dart';

void main() {
  test('la escala de texto llega a 2.0 y no pasa de ahí', () {
    expect(
      AppTextScaling.clamp(TextScaler.linear(2)).scale(10),
      20,
    );
    expect(
      AppTextScaling.clamp(TextScaler.linear(3)).scale(10),
      20,
    );
  });

  testWidgets('la solicitud pendiente cabe a 320 dp y escala 2', (tester) async {
    await initializeDateFormatting('es_CL');
    final job = JobModel(
      id: 'job-1',
      userId: 'client-1',
      serviceId: 'svc',
      status: AppConstants.jobStatusPending,
      address: 'Providencia 1234',
      description: 'Cambio de llave de paso',
      serviceMetadata: const {'worker_tier_price_clp': 45000},
      createdAt: DateTime.utc(2026, 11, 14),
      updatedAt: DateTime.utc(2026, 11, 14),
    );
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: WorkerJobCard(
              job: job,
              clientName: 'Camila Soto',
              clientRatingLabel: 'Cliente nuevo',
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Camila Soto'), findsOneWidget);
    expect(find.textContaining('Oferta'), findsOneWidget);
    expect(find.text('Cliente nuevo'), findsOneWidget);
    expect(find.textContaining('teléfono'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
