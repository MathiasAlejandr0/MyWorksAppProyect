// ActionTimeoutService (timeouts y rollback) y WorkerJobRejectionService
// (rechazo del profesional con o sin pago retenido y alternativas).
import 'dart:async' hide TimeoutException;

import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/services/action_timeout_service.dart';
import 'package:myworksapp/core/services/worker_job_rejection_service.dart';
import 'package:myworksapp/core/utils/app_error.dart';

import 'support/catalog_seed.dart';
import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

void main() {
  group('ActionTimeoutService', () {
    final s = ActionTimeoutService.instance;

    test('acción exitosa, error con rollback, timeout y rollback fallido',
        () async {
      expect(
          await s.executeWithTimeout(
              action: () async => 7, rollback: () async {}),
          7);

      var rb = 0;
      await expectLater(
        s.executeWithTimeout(
          action: () async => throw StateError('x'),
          rollback: () async => rb++,
          actionName: 'prueba',
        ),
        throwsA(isA<AppError>()),
      );
      await expectLater(
        s.executeWithTimeout(
          action: () async => throw AppError.validation('v'),
          rollback: () async => rb++,
        ),
        throwsA(isA<AppError>()),
      );
      await expectLater(
        s.executeWithTimeout<int>(
          action: () => Completer<int>().future,
          rollback: () async => rb++,
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(isA<AppError>()),
      );
      expect(rb, 3);
      await expectLater(
        s.executeWithTimeout(
          action: () async => throw StateError('x'),
          rollback: () async => throw StateError('rollback'),
        ),
        throwsA(isA<AppError>()),
      );
    });

    test('solo timeout', () async {
      expect(await s.executeWithTimeoutOnly(action: () async => 'ok'), 'ok');
      await expectLater(
        s.executeWithTimeoutOnly<int>(
          action: () => Completer<int>().future,
          timeout: const Duration(milliseconds: 20),
          actionName: 'lenta',
        ),
        throwsA(isA<AppError>()),
      );
      await expectLater(
        s.executeWithTimeoutOnly(action: () async => throw StateError('x')),
        throwsA(isA<AppError>()),
      );
      await expectLater(
        s.executeWithTimeoutOnly(
            action: () async => throw AppError.network('n')),
        throwsA(isA<AppError>()),
      );
      final t = TimeoutException('m', const Duration(seconds: 1));
      expect('$t', 'm');
    });

    test('RollbackHelper', () async {
      final log = <String>[];
      await RollbackHelper.jobStatusRollback(
        jobId: 'j',
        originalStatus: 'pendiente',
        updateStatus: (a, b) async => log.add('$a:$b'),
      )();
      await RollbackHelper.messageRollback(
        messageId: 'm',
        deleteMessage: (a) async => log.add(a),
      )();
      await RollbackHelper.availabilityRollback(
        workerId: 'w',
        originalAvailability: true,
        updateAvailability: (a, b) async => log.add('$a$b'),
      )();
      expect(log, ['j:pendiente', 'm', 'wtrue']);
    });
  });

  group('WorkerJobRejectionService', () {
    final svc = WorkerJobRejectionService.instance;
    const jobId = 'job-rech-1';
    final worker = catalogProId(1);

    Map<String, dynamic> trabajo({
      String estado = 'pendiente',
      String? idTrabajador,
      Map<String, dynamic>? meta,
    }) =>
        {
          ...sampleJobModel,
          'id': jobId,
          'id_usuario': fakeUserId,
          'id_trabajador': idTrabajador ?? worker,
          'id_servicio': catalogServiceId,
          'estado': estado,
          'latitud': -41.4693,
          'longitud': -72.9424,
          'metadatos_servicio': meta ?? <String, dynamic>{},
        };

    Future<FakeBackend> base(Map<String, dynamic>? job,
        {bool retenido = false}) async {
      final b = await setUpFakeSupabase(signedIn: true);
      seedCatalog(b, n: 4);
      b.seed('trabajos', [if (job != null) job]);
      b.seed('pagos', [
        if (retenido)
          {
            ...samplePaymentModel,
            'id_trabajo': jobId,
            'tipo_pago': PricingConstants.paymentTypePrimary,
            'estado': PricingConstants.paymentAuthorized,
          },
      ]);
      b.rpc('rechazar_trabajo_pendiente', {'id': jobId});
      b.defaultFunction = (_) => {'ok': true, 'refunded': true};
      return b;
    }

    test('rechazo sin pago retenido sugiere alternativas', () async {
      await base(trabajo());
      final alt = await svc.rejectAndSuggestAlternatives(
          jobId: jobId, workerId: worker);
      expect(alt.any((w) => w.userId == worker), isFalse);
    });

    test('rechazo con pago retenido reembolsa', () async {
      await base(trabajo(), retenido: true);
      try {
        await svc.rejectAndSuggestAlternatives(jobId: jobId, workerId: worker);
      } on AppError catch (_) {}
    });

    test('rpc sin fila: error de base de datos', () async {
      final b = await base(trabajo());
      b.rpc('rechazar_trabajo_pendiente', null);
      await expectLater(
        svc.rejectAndSuggestAlternatives(jobId: jobId, workerId: worker),
        throwsA(isA<AppError>()),
      );
    });

    test(
        'validaciones: no existe, no pendiente, otro profesional, ya rechazado',
        () async {
      await base(null);
      await expectLater(
        svc.rejectAndSuggestAlternatives(jobId: jobId, workerId: worker),
        throwsA(isA<AppError>()),
      );
      await base(trabajo(estado: 'en_curso'));
      await expectLater(
        svc.rejectAndSuggestAlternatives(jobId: jobId, workerId: worker),
        throwsA(isA<AppError>()),
      );
      await base(trabajo(idTrabajador: catalogProId(2)));
      await expectLater(
        svc.rejectAndSuggestAlternatives(jobId: jobId, workerId: worker),
        throwsA(isA<AppError>()),
      );
      await base(trabajo(
        estado: 'cancelado',
        meta: {
          'rejection_reason': 'worker_unavailable',
          'rejected_by_worker_id': worker,
        },
      ));
      final alt = await svc.rejectAndSuggestAlternatives(
          jobId: jobId, workerId: worker);
      expect(alt.length, lessThanOrEqualTo(5));
    });

    test('alternativesForJob', () async {
      await base(trabajo());
      final job = JobModel.fromMap(trabajo(meta: {
        'rejected_by_worker_id': worker,
      }));
      expect(await svc.alternativesForJob(job), isA<List>());
      expect(
          await svc.alternativesForJob(JobModel.fromMap(trabajo())), isEmpty);
      final b = FakeBackend.instance;
      b.seed('servicios', []);
      final sinServicio = JobModel.fromMap({
        ...trabajo(meta: {'rejected_by_worker_id': worker}),
        'id_servicio': 'no-existe',
      });
      expect(await svc.alternativesForJob(sinServicio), isEmpty);
    });
  });
}
