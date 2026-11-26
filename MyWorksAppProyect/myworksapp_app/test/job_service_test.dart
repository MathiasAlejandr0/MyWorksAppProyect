// JobService contra el backend falso con filas realistas: creación con sus
// validaciones, aceptar, rechazar, cambio de estado (permisos, transición, PIN)
// y consultas.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/repositories/service_repository.dart';
import 'package:myworksapp/core/services/job_service.dart';
import 'package:myworksapp/core/utils/app_error.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

const _id = '00000000-0000-4000-8000-0000000000aa';
final _s = JobService.instance;

Future<FakeBackend> _b({
  Map<String, dynamic> over = const {},
  List<String> destinos = const [
    'aceptado',
    'en_curso',
    'completado',
    'cancelado'
  ],
  bool vacio = false,
}) async {
  ServiceRepository.clearCache();
  final b = await setUpFakeSupabase(signedIn: true);
  if (!vacio) {
    b.defaultRows = [universalRow];
    b.tableDefaults = tableRows;
    b.rowOverrides = {
      'rol': 'usuario',
      'categoria': 'limpieza',
      'activo': 1,
      'requiere_certificacion': 0,
      'id_trabajador': fakeUserId,
      ...over,
    };
    b.defaultRpc = (_) => null;
  } else {
    b.defaultRows = [];
  }
  b.rpc('transiciones_trabajo_posibles', destinos);
  return b;
}

Future<Object?> _err(Future<Object?> Function() f) async {
  try {
    return await f();
  } catch (e) {
    return e;
  }
}

Future<Object?> _crear({String desc = 'Limpieza profunda del living'}) => _err(
      () => _s.createJob(
        userId: fakeUserId,
        serviceId: _id,
        description: desc,
        address: ' Calle 1, Puerto Montt ',
        latitude: -41.47,
        longitude: -72.94,
        scheduledDate: DateTime.utc(2026, 12, 1, 15),
        serviceMetadata: {'variant': 'basica'},
      ),
    );

void main() {
  test('createJob: validaciones y creación', () async {
    await _b(vacio: true);
    expect(await _crear(), isA<AppError>());
    await _b(over: {'rol': 'trabajador'});
    expect(await _crear(), isA<AppError>());
    await _b();
    expect(await _crear(desc: '   '), isA<AppError>());
    expect(await _crear(desc: 'corta'), isA<AppError>());
    await _b(over: {'categoria': 'otra'});
    expect(await _crear(), isA<AppError>());
    await _b();
    await _crear();
    final b = await _b();
    b.failing.add('trabajos');
    await _crear();
  });

  test('acceptJob y rejectJob', () async {
    await _b(vacio: true);
    expect(await _err(() => _s.acceptJob(jobId: _id, workerId: _id)),
        isA<AppError>());
    expect(await _err(() => _s.rejectJob(jobId: _id, workerId: _id)),
        isA<AppError>());
    await _b(over: {'estado': 'aceptado'});
    expect(await _err(() => _s.acceptJob(jobId: _id, workerId: _id)),
        isA<AppError>());
    await _b(over: {'estado': 'pendiente'});
    await _err(() => _s.acceptJob(jobId: _id, workerId: _id));
    expect(await _s.rejectJob(jobId: _id, workerId: _id), isTrue);
    final b = await _b();
    b.failAll = true;
    await _err(() => _s.acceptJob(jobId: _id, workerId: _id));
    await _err(() => _s.rejectJob(jobId: _id, workerId: _id));
  });

  test('updateJobStatus: permisos, transición, PIN y avisos', () async {
    Future<Object?> up(String to, {String? user, String? pin}) => _err(
          () => _s.updateJobStatus(
              jobId: _id, newStatus: to, userId: user, pin: pin),
        );
    await _b(vacio: true);
    expect(await up('aceptado'), isA<AppError>());
    await _b(over: {
      'estado': 'pendiente',
      'id_usuario': 'otro',
      'id_trabajador': 'otro'
    });
    expect(await up('aceptado', user: fakeUserId), isA<AppError>());
    await _b(over: {'estado': 'pendiente'}, destinos: const []);
    expect(await up('aceptado'), isA<AppError>());
    await _b(over: {'estado': 'aceptado'});
    expect(await up('en_curso'), isA<AppError>());
    for (final to in ['en_curso', 'completado', 'cancelado', 'aceptado']) {
      await _b(over: {'estado': 'aceptado'});
      await up(to, pin: '1234', user: fakeUserId);
    }
    final b = await _b(over: {'estado': 'aceptado'});
    b.failing.add('trabajos');
    await up('completado');
  });

  test('consultas con datos y con error', () async {
    for (final falla in [false, true]) {
      final b = await _b();
      b.failAll = falla;
      await _s.getUserJobs(fakeUserId);
      await _s.getWorkerJobs(fakeUserId);
      await _s.getAvailableJobs();
      await _s.getJobById(_id);
    }
  });
}
