import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/utils/constants.dart';
import 'package:myworksapp/features/jobs/presentation/widgets/job_detail_actions_section.dart';

JobModel _completedJob() {
  final now = DateTime.utc(2026, 1, 1);
  return JobModel(
    id: 'job-1',
    userId: 'cliente',
    workerId: 'pro',
    serviceId: 'svc-1',
    status: AppConstants.jobStatusCompleted,
    address: 'Test',
    createdAt: now,
    updatedAt: now,
  );
}

Widget _section({required bool alreadyRated}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: JobDetailActionsSection(
          jobId: 'job-1',
          job: _completedJob(),
          isWorker: false,
          isOwner: true,
          canTransition: const {},
          onGoToDashboard: () {},
          onCancelJob: () async {},
          onAcceptJob: () {},
          onRejectJob: () async {},
          onMarkEnRoute: () {},
          onStartJob: () {},
          onRequestOvertimeHours: () {},
          onCompleteJob: () {},
          alreadyRated: alreadyRated,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sin calificación, el cliente ve «Calificar Trabajo»',
      (tester) async {
    await tester.pumpWidget(_section(alreadyRated: false));
    expect(find.text('Calificar Trabajo'), findsOneWidget);
    expect(find.text('Ya calificaste este trabajo.'), findsNothing);
  });

  testWidgets('si ya calificó (por ejemplo en la web), el botón se oculta',
      (tester) async {
    await tester.pumpWidget(_section(alreadyRated: true));
    expect(find.text('Calificar Trabajo'), findsNothing);
    expect(find.text('Ya calificaste este trabajo.'), findsOneWidget);
  });
}
