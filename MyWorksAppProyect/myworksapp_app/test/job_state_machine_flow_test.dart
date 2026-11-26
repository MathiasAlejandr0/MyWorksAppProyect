// Flujo de JobStateMachine contra el Supabase falso: transiciones válidas e
// inválidas, permisos por actor, PIN de inicio, reembolso al cancelar y
// expiración por timeout. No toca producción.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/services/job_state_machine.dart';
import 'package:myworksapp/core/utils/app_error.dart';

import 'support/fake_supabase.dart';

const _client = fakeUserId;
const _worker = '00000000-0000-4000-8000-0000000000w1';

Map<String, dynamic> _job({
  String id = 'job-1',
  String estado = 'aceptado',
  String modalidad = 'legado',
  String? worker = _worker,
  DateTime? creado,
  DateTime? actualizado,
}) {
  final c = (creado ?? DateTime.now().toUtc()).toIso8601String();
  return {
    'id': id,
    'id_usuario': _client,
    'id_trabajador': worker,
    'id_servicio': 'srv-1',
    'estado': estado,
    'direccion': 'Calle 1, Puerto Montt',
    'modalidad_cobro': modalidad,
    'estado_pago': 'ninguno',
    'creado_en': c,
    'actualizado_en': (actualizado ?? DateTime.parse(c)).toIso8601String(),
  };
}

void main() {
  late FakeBackend b;
  final sm = JobStateMachine.instance;

  setUp(() async {
    b = await setUpFakeSupabase(signedIn: true);
  });

  group('actorMayTransition', () {
    test('el cliente puede cancelar y el profesional rechazar pendiente', () {
      expect(
        actorMayTransition(
          jobWorkerId: _worker,
          jobClientId: _client,
          jobStatus: 'aceptado',
          newStatus: 'cancelado',
          actorId: _client,
        ),
        isTrue,
      );
      expect(
        actorMayTransition(
          jobWorkerId: _worker,
          jobClientId: _client,
          jobStatus: 'pendiente',
          newStatus: 'cancelado',
          actorId: _worker,
        ),
        isTrue,
      );
    });
    test('el profesional no cancela un trabajo aceptado', () {
      expect(
        actorMayTransition(
          jobWorkerId: _worker,
          jobClientId: _client,
          jobStatus: 'aceptado',
          newStatus: 'cancelado',
          actorId: _worker,
        ),
        isFalse,
      );
    });
    test('acciones por rol y terceros', () {
      bool may(String actor, String to) => actorMayTransition(
            jobWorkerId: _worker,
            jobClientId: _client,
            jobStatus: 'aceptado',
            newStatus: to,
            actorId: actor,
          );
      expect(may(_worker, 'en_camino'), isTrue);
      expect(may(_worker, 'cotizacion_seleccionada'), isFalse);
      expect(may(_client, 'cotizacion_seleccionada'), isTrue);
      expect(may(_client, 'en_camino'), isFalse);
      expect(may('otro', 'en_camino'), isFalse);
    });
  });

  group('transitionTo', () {
    test('rechaza un trabajo que no existe', () async {
      b.seed('trabajos', []);
      await expectLater(
        sm.transitionTo(jobId: 'nada', newStatus: 'en_camino'),
        throwsA(isA<AppError>()),
      );
    });

    test('rechaza una transición que la base no permite', () async {
      b.seed('trabajos', [_job()]);
      b.rpc('transiciones_trabajo_posibles', ['en_camino']);
      await expectLater(
        sm.transitionTo(jobId: 'job-1', newStatus: 'completado'),
        throwsA(
          isA<AppError>().having(
            (e) => e.message,
            'mensaje',
            contains('aceptado a completado'),
          ),
        ),
      );
    });

    test('rechaza a un actor sin permiso', () async {
      b.seed('trabajos', [_job()]);
      b.rpc('transiciones_trabajo_posibles', ['en_camino']);
      await expectLater(
        sm.transitionTo(jobId: 'job-1', newStatus: 'en_camino', userId: 'otro'),
        throwsA(isA<AppError>()),
      );
    });

    test('el profesional pasa a en camino y se llama al RPC', () async {
      b.seed('trabajos', [_job()]);
      b.rpc('transiciones_trabajo_posibles', ['en_camino', 'cancelado']);
      final job = await sm.transitionTo(
        jobId: 'job-1',
        newStatus: 'en_camino',
        userId: _worker,
      );
      expect(job.status, 'en_camino');
      final rpc = b.calls('rpc/transicionar_trabajo').single;
      expect(rpc.json['p_nuevo_estado'], 'en_camino');
      expect((rpc.json as Map).containsKey('p_pin'), isFalse);
    });

    test('iniciar exige PIN y lo valida con la base', () async {
      b.seed('trabajos', [_job(estado: 'en_camino')]);
      b.seed('fotos_trabajo', []);
      b.rpc('transiciones_trabajo_posibles', ['en_curso']);
      await expectLater(
        sm.transitionTo(jobId: 'job-1', newStatus: 'en_curso', userId: _worker),
        throwsA(isA<AppError>()),
      );
      b.rpc('intentar_pin_inicio', {'ok': false, 'mensaje': 'PIN incorrecto'});
      await expectLater(
        sm.transitionTo(
          jobId: 'job-1',
          newStatus: 'en_curso',
          userId: _worker,
          pin: '0000',
        ),
        throwsA(isA<AppError>()),
      );
      b.rpc('intentar_pin_inicio', {'ok': true});
      final job = await sm.transitionTo(
        jobId: 'job-1',
        newStatus: 'en_curso',
        userId: _worker,
        pin: ' 1234 ',
      );
      expect(job.status, 'en_curso');
      expect(
        b.calls('rpc/intentar_pin_inicio').last.json['p_pin'],
        '1234',
      );
    });

    test('cancelar pide el reembolso antes de cambiar el estado', () async {
      b.seed('trabajos', [_job()]);
      b.rpc('transiciones_trabajo_posibles', ['cancelado']);
      b.functions['webpay-refund-cancellation'] = (_) => {'skipped': true};
      final job = await sm.transitionTo(
        jobId: 'job-1',
        newStatus: 'cancelado',
        userId: _client,
      );
      expect(job.status, 'cancelado');
      final paths = b.requests.map((r) => r.path).toList();
      expect(
        paths.indexOf('/functions/v1/webpay-refund-cancellation'),
        lessThan(paths.indexOf('/rest/v1/rpc/transicionar_trabajo')),
      );
    });

    test('si el reembolso falla, no cambia el estado', () async {
      b.seed('trabajos', [_job()]);
      b.rpc('transiciones_trabajo_posibles', ['cancelado']);
      b.functions['webpay-refund-cancellation'] = (_) => {'error': 'sin pago'};
      await expectLater(
        sm.transitionTo(jobId: 'job-1', newStatus: 'cancelado'),
        throwsA(isA<AppError>()),
      );
      expect(b.calls('rpc/transicionar_trabajo'), isEmpty);
    });

    test('un error inesperado se convierte en AppError', () async {
      b.failing.add('trabajos');
      await expectLater(
        sm.transitionTo(jobId: 'job-1', newStatus: 'en_camino'),
        throwsA(isA<AppError>()),
      );
    });
  });

  test('processTimeouts expira pendientes viejos y deja los recientes', () async {
    final viejo = DateTime.now().toUtc().subtract(const Duration(hours: 2));
    b.seed('trabajos', [
      _job(id: 'viejo', estado: 'pendiente', worker: null, creado: viejo),
      _job(id: 'nuevo', estado: 'pendiente', worker: null),
    ]);
    b.rpc('transiciones_trabajo_posibles', ['expirado']);
    await sm.processTimeouts();
    final ids = b
        .calls('rpc/transicionar_trabajo')
        .map((r) => r.json['p_trabajo_id'])
        .toList();
    expect(ids, contains('viejo'));
    expect(ids, isNot(contains('nuevo')));
  });

  test('processTimeouts no lanza si la base falla', () async {
    b.failAll = true;
    await sm.processTimeouts();
  });

  group('sugerencias y estados finales', () {
    JobModel job(String estado) => JobModel.fromMap(_job(estado: estado));

    test('siguiente estado sugerido', () async {
      b.rpc('transiciones_trabajo_posibles', ['aceptado', 'cancelado']);
      expect(await sm.getSuggestedNextStatus(job('pendiente')), 'aceptado');
      b.rpc('transiciones_trabajo_posibles', ['cancelado']);
      expect(await sm.getSuggestedNextStatus(job('pendiente')), 'cancelado');
      b.rpc('transiciones_trabajo_posibles', ['x']);
      expect(await sm.getSuggestedNextStatus(job('aceptado')), 'en_camino');
      expect(await sm.getSuggestedNextStatus(job('en_camino')), 'en_curso');
      expect(await sm.getSuggestedNextStatus(job('en_curso')), 'completado');
      expect(await sm.getSuggestedNextStatus(job('otro')), 'x');
      b.rpc('transiciones_trabajo_posibles', []);
      expect(await sm.getSuggestedNextStatus(job('aceptado')), isNull);
    });

    test('cancelar y completar', () async {
      b.rpc('transiciones_trabajo_posibles', ['cancelado']);
      expect(await sm.canCancel(job('aceptado')), isTrue);
      b.rpc('transiciones_trabajo_posibles', null);
      expect(await sm.canCancel(job('aceptado')), isFalse);
      expect(sm.canComplete(job('en_curso')), isTrue);
      expect(sm.canComplete(job('aceptado')), isFalse);
    });

    test('estados finales', () {
      expect(JobStateMachine.isFinalState('completado'), isTrue);
      expect(JobStateMachine.isFinalState('no_asistio'), isTrue);
      expect(JobStateMachine.isFinalState('en_curso'), isFalse);
    });
  });
}
