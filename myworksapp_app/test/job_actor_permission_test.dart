import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/job_state_machine.dart';
import 'package:myworksapp/core/utils/constants.dart';

void main() {
  const worker = 'worker-carmen';
  const client = 'client-1';

  test('el profesional asignado puede rechazar una oferta pendiente', () {
    expect(
      actorMayTransition(
        jobWorkerId: worker,
        jobClientId: client,
        jobStatus: AppConstants.jobStatusPending,
        newStatus: AppConstants.jobStatusCancelled,
        actorId: worker,
      ),
      isTrue,
    );
  });

  test('otro profesional no puede rechazar la oferta', () {
    expect(
      actorMayTransition(
        jobWorkerId: worker,
        jobClientId: client,
        jobStatus: AppConstants.jobStatusPending,
        newStatus: AppConstants.jobStatusCancelled,
        actorId: 'otro',
      ),
      isFalse,
    );
  });

  test('el profesional no cancela un trabajo ya en curso', () {
    expect(
      actorMayTransition(
        jobWorkerId: worker,
        jobClientId: client,
        jobStatus: AppConstants.jobStatusInProgress,
        newStatus: AppConstants.jobStatusCancelled,
        actorId: worker,
      ),
      isFalse,
    );
  });

  test('el cliente sigue pudiendo cancelar', () {
    expect(
      actorMayTransition(
        jobWorkerId: worker,
        jobClientId: client,
        jobStatus: AppConstants.jobStatusPending,
        newStatus: AppConstants.jobStatusCancelled,
        actorId: client,
      ),
      isTrue,
    );
  });

  test('el profesional sigue pudiendo aceptar', () {
    expect(
      actorMayTransition(
        jobWorkerId: worker,
        jobClientId: client,
        jobStatus: AppConstants.jobStatusPending,
        newStatus: AppConstants.jobStatusAccepted,
        actorId: worker,
      ),
      isTrue,
    );
  });

  test('el cliente no marca el trabajo en camino', () {
    expect(
      actorMayTransition(
        jobWorkerId: worker,
        jobClientId: client,
        jobStatus: AppConstants.jobStatusAccepted,
        newStatus: AppConstants.jobStatusEnRoute,
        actorId: client,
      ),
      isFalse,
    );
  });
}
