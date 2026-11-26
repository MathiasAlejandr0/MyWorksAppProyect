// AnalyticsService con un repositorio en memoria: métricas de negocio
// (conversión, aceptación, tiempo de respuesta, cancelación por servicio,
// recurrencia) y la tolerancia a fallas del repositorio.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/analytics_event_model.dart';
import 'package:myworksapp/core/database/repositories/analytics_repository.dart';
import 'package:myworksapp/core/interfaces/analytics_repository_interface.dart';
import 'package:myworksapp/core/services/analytics_service.dart';

class _Repo implements IAnalyticsRepository {
  _Repo({this.falla = false});

  final bool falla;
  final eventos = <AnalyticsEventModel>[];

  void _quizas() {
    if (falla) throw StateError('repositorio caído');
  }

  @override
  Future<void> trackEvent(AnalyticsEventModel event) async {
    _quizas();
    eventos.add(event);
  }

  @override
  Future<void> trackEvents(List<AnalyticsEventModel> events) async {
    _quizas();
    eventos.addAll(events);
  }

  @override
  Future<List<AnalyticsEventModel>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventName,
    String? userId,
  }) async {
    _quizas();
    return eventos
        .where((e) => eventName == null || e.eventName == eventName)
        .toList();
  }

  @override
  Future<void> cleanOldEvents(int daysToKeep) async => _quizas();

  @override
  Future<Map<String, int>> getEventCounts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _quizas();
    final out = <String, int>{};
    for (final e in eventos) {
      out[e.eventName] = (out[e.eventName] ?? 0) + 1;
    }
    return out;
  }

  @override
  Future<void> syncPendingEvents() async => _quizas();
}

AnalyticsEventModel _ev(String name, DateTime ts,
        {String? user, Map<String, dynamic> meta = const {}}) =>
    AnalyticsEventModel(
      id: '$name-${ts.millisecondsSinceEpoch}-$user',
      eventName: name,
      userId: user,
      timestamp: ts,
      metadata: meta,
    );

void main() {
  final svc = AnalyticsService.instance;
  tearDown(() {
    svc.setRepository(AnalyticsRepository());
    svc.setEnabled(true);
  });

  test('métricas con eventos reales', () async {
    final repo = _Repo();
    svc.setRepository(repo);
    final t0 = DateTime(2026, 5, 1, 10);
    repo.eventos.addAll([
      _ev(AnalyticsEvents.registerCompleted, t0, user: 'u1'),
      _ev(AnalyticsEvents.registerCompleted, t0, user: 'u2'),
      for (var i = 0; i < 3; i++)
        _ev(AnalyticsEvents.jobCreated, t0.add(Duration(minutes: i)),
            user: i == 2 ? 'u2' : 'u1',
            meta: {'jobId': 'j$i', 'serviceId': i.isEven ? 's1' : 's2'}),
      _ev(AnalyticsEvents.jobAccepted, t0.add(const Duration(minutes: 30)),
          meta: {'jobId': 'j0'}),
      _ev(AnalyticsEvents.jobAccepted, t0.add(const Duration(minutes: 50)),
          meta: {'jobId': 'j1'}),
      _ev(AnalyticsEvents.jobAccepted, t0, meta: {'jobId': 'otro'}),
      _ev(AnalyticsEvents.jobCancelled, t0, meta: {'serviceId': 's1'}),
      _ev(AnalyticsEvents.jobCancelled, t0, meta: const {}),
    ]);

    expect(await svc.calculateUserToRequestConversion(), greaterThan(0));
    expect(await svc.calculateWorkerAcceptanceRate(), greaterThan(0));
    expect(await svc.calculateAverageResponseTime(), greaterThan(0));
    final porServicio = await svc.calculateCancellationRateByService();
    expect(porServicio.keys, contains('s1'));
    expect(await svc.calculateUserRepeatRate(), greaterThan(0));
    final m = await svc.getBusinessMetrics();
    expect(m.cancellationRateByService, isNotEmpty);
    expect(await svc.getEventStats(), isNotEmpty);
    await svc.cleanOldEvents();
    await svc.syncPendingEvents();
    await svc.trackEventWithCategory(
      eventName: 'evento_categoria',
      category: AnalyticsService.categoryUX,
      metadata: const {'pantalla': 'inicio'},
    );
    await svc.trackRatingSubmitted(
      jobId: 'j0',
      workerId: 'w1',
      score: 5,
      hasComment: true,
    );
    svc.registrarUso(eventName: 'uso', userId: 'u1');
    svc.registrarUso(eventName: 'uso_anonimo');
    svc.setEnabled(false);
    await svc.trackEvent(eventName: 'no_se_registra');
  });

  test('métricas sin eventos', () async {
    svc.setRepository(_Repo());
    expect(await svc.calculateUserToRequestConversion(), 0);
    expect(await svc.calculateWorkerAcceptanceRate(), 0);
    expect(await svc.calculateAverageResponseTime(), 0);
    expect(await svc.calculateCancellationRateByService(), isEmpty);
    expect(await svc.calculateUserRepeatRate(), 0);
  });

  test('repositorio caído no rompe la app', () async {
    svc.setRepository(_Repo(falla: true));
    await svc.trackEvent(eventName: 'x', userId: 'u1');
    expect(await svc.getEventStats(), isEmpty);
    await svc.cleanOldEvents(daysToKeep: 10);
    await svc.syncPendingEvents();
    expect(await svc.calculateUserToRequestConversion(), 0);
    expect(await svc.calculateWorkerAcceptanceRate(), 0);
    expect(await svc.calculateAverageResponseTime(), 0);
    expect(await svc.calculateCancellationRateByService(), isEmpty);
    expect(await svc.calculateUserRepeatRate(), 0);
    final m = await svc.getBusinessMetrics();
    expect(m.cancellationRateByService, isEmpty);
  });
}
