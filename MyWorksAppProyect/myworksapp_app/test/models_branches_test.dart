import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/app_error_log_model.dart';
import 'package:myworksapp/core/database/models/job_model.dart';
import 'package:myworksapp/core/database/models/quote_proposal_model.dart';
import 'package:myworksapp/core/database/models/ranking_models.dart';
import 'package:myworksapp/core/database/models/rating_model.dart';
import 'package:myworksapp/core/database/models/service_config_model.dart';
import 'package:myworksapp/core/database/models/service_model.dart';
import 'package:myworksapp/core/database/models/user_model.dart';
import 'package:myworksapp/core/database/models/worker_review_model.dart';

void main() {
  final t = DateTime.utc(2026, 1, 2);

  test('AppErrorLogModel copia los metadatos cuando vienen como mapa', () {
    final m = AppErrorLogModel.fromMap({
      'id': 'e1',
      'mensaje': 'boom',
      'metadatos': {'pantalla': 'home'},
      'creado_en': t.toIso8601String(),
    });
    expect(m.metadata, {'pantalla': 'home'});
    expect(m.errorType, 'error');
  });

  test('JobModel serializa metadatos y snapshot de precio como JSON', () {
    final job = JobModel(
      id: 'j1',
      userId: 'u1',
      serviceId: 's1',
      status: 'pendiente',
      address: 'Calle 1',
      serviceMetadata: {'m2': 20},
      pricingSnapshot: {'total': 1000},
      scheduledDate: t,
      createdAt: t,
      updatedAt: t,
    );
    final map = job.toMap();
    expect(map['metadatos_servicio'], '{"m2":20}');
    expect(map['instantanea_precio'], '{"total":1000}');
    final back = JobModel.fromMap(map);
    expect(back.serviceMetadata, {'m2': 20});
    expect(back.scheduledDate, t);
  });

  test('QuoteProposalModel arma líneas de materiales y mano de obra', () {
    final q = QuoteProposalModel(
      id: 'q1',
      jobId: 'j1',
      workerId: 'w1',
      montoTotalClp: 30000,
      descripcion: 'Arreglo',
      estado: 'enviada',
      createdAt: t,
      desglose: {'materiales_clp': 10000, 'mano_obra_clp': 20000},
    );
    final rows = q.itemRows();
    expect(rows.length, 2);
    expect(rows.first['linea'], 1);
  });

  test('RankingConfig lee números como texto, mapas de señales y copia', () {
    final c = RankingConfig.fromMap({
      'peso_calificacion': '0.5',
      'peso_completados': 'x',
      'aprendizaje_activo': '0',
      'pesos_senal': {'a': 1, 'b': '0.2'},
      'actualizado_en': t.toIso8601String(),
    });
    expect(c.pesoCalificacion, 0.5);
    expect(c.pesoCompletados, 0.18);
    expect(c.aprendizajeActivo, isFalse);
    expect(c.pesosSenal, {'a': 1.0, 'b': 0.2});
    final rpc = c.toRpcMap();
    expect(rpc['aprendizaje_activo'], 0);
    expect(rpc['pesos_senal'], isNotNull);
    final copy = c.copyWith(pesoImpulso: 0.9, aprendizajeActivo: true);
    expect(copy.pesoImpulso, 0.9);
    expect(copy.toRpcMap()['aprendizaje_activo'], 1);
    expect(
        const RankingConfig().toRpcMap().containsKey('pesos_senal'), isFalse);
  });

  test('RatingModel acepta fechas con espacio y zona +00', () {
    final r = RatingModel.fromMap({
      'id': 'r1',
      'id_trabajo': 'j1',
      'puntaje': 4.6,
      'creado_en': '2026-01-02 03:04:05+00',
    });
    expect(r.score, 5);
    expect(r.createdAt.isUtc, isTrue);
  });

  test('ServiceConfigModel lista solo los campos requeridos con nombre', () {
    final c = ServiceConfigModel.fromMap({
      'id': 'c1',
      'id_servicio': 's1',
      'esquema_config':
          '{"fields":[{"nombre":"m2","required":true},{"nombre":"x"},'
              '{"required":true},"no-mapa"]}',
      'creado_en': t.toIso8601String(),
      'actualizado_en': t.toIso8601String(),
    });
    expect(c.getRequiredFields(), ['m2']);
    final vacio = ServiceConfigModel.fromMap({
      'id': 'c2',
      'id_servicio': 's1',
      'esquema_config': 'no es json',
      'creado_en': t.toIso8601String(),
      'actualizado_en': t.toIso8601String(),
    });
    expect(vacio.configSchema, isEmpty);
    expect(vacio.getRequiredFields(), isEmpty);
  });

  test('ServiceModel usa la fecha actual si faltan las fechas', () {
    final s = ServiceModel.fromMap({
      'id': 's1',
      'nombre': 'Gasfitería',
      'creado_en': null,
      'actualizado_en': null,
    });
    expect(s.createdAt.year, greaterThanOrEqualTo(2026));
    final s2 = ServiceModel.fromMap({
      'id': 's1',
      'nombre': 'Gasfitería',
      'creado_en': t.toIso8601String(),
      'actualizado_en': t.toIso8601String(),
    });
    expect(s2.updatedAt, t);
  });

  test('UserModel.publicCard no expone correo', () {
    final u = UserModel.publicCard({'id': 'u1', 'nombre': 'Ana'});
    expect(u.email, '');
    expect(u.role, 'usuario');
    expect(UserModel.publicCard({'id': 'u2'}).name, '');
  });

  group('WorkerReviewModel', () {
    WorkerReviewModel r({String? name, String? comment}) => WorkerReviewModel(
          id: 'r',
          score: 5,
          createdAt: t,
          reviewerName: name,
          comment: comment,
        );
    test('nombre visible', () {
      expect(r().displayReviewerName, 'Cliente verificado');
      expect(r(name: '  ').displayReviewerName, 'Cliente verificado');
      expect(r(name: 'Ana').displayReviewerName, 'Ana');
      expect(r(name: 'Ana maría pérez').displayReviewerName, 'Ana P.');
    });
    test('comentario', () {
      expect(r().hasComment, isFalse);
      expect(r(comment: ' ').hasComment, isFalse);
      expect(r(comment: 'Bien').hasComment, isTrue);
    });
  });
}
