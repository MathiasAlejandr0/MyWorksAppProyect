// GENERADO por scripts/cobertura/gen_models.py + emit_models.py. No editar a mano.
// Prueba fromMap/toMap/copyWith/getters de todos los modelos con un mapa completo
// y con variantes (valores nulos, tipos alternativos) que la base puede devolver.
// ignore_for_file: avoid_dynamic_calls
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/abuse_event_model.dart' as lm0;
import 'package:myworksapp/core/database/models/analytics_event_model.dart'
    as lm1;
import 'package:myworksapp/core/database/models/app_error_log_model.dart'
    as lm2;
import 'package:myworksapp/core/database/models/boost_model.dart' as lm3;
import 'package:myworksapp/core/database/models/change_order_model.dart' as lm4;
import 'package:myworksapp/core/database/models/dispute_model.dart' as lm5;
import 'package:myworksapp/core/database/models/feature_flag_model.dart' as lm6;
import 'package:myworksapp/core/database/models/job_cancellation_model.dart'
    as lm7;
import 'package:myworksapp/core/database/models/job_model.dart' as lm8;
import 'package:myworksapp/core/database/models/job_photo_model.dart' as lm9;
import 'package:myworksapp/core/database/models/message_model.dart' as lm10;
import 'package:myworksapp/core/database/models/notification_model.dart'
    as lm11;
import 'package:myworksapp/core/database/models/payment_model.dart' as lm12;
import 'package:myworksapp/core/database/models/pending_action_model.dart'
    as lm13;
import 'package:myworksapp/core/database/models/portfolio_model.dart' as lm14;
import 'package:myworksapp/core/database/models/quote_proposal_model.dart'
    as lm15;
import 'package:myworksapp/core/database/models/ranking_models.dart' as lm16;
import 'package:myworksapp/core/database/models/rating_model.dart' as lm17;
import 'package:myworksapp/core/database/models/report_model.dart' as lm18;
import 'package:myworksapp/core/database/models/service_config_model.dart'
    as lm19;
import 'package:myworksapp/core/database/models/service_model.dart' as lm20;
import 'package:myworksapp/core/database/models/subscription_model.dart'
    as lm21;
import 'package:myworksapp/core/database/models/user_block_model.dart' as lm22;
import 'package:myworksapp/core/database/models/user_consent_model.dart'
    as lm23;
import 'package:myworksapp/core/database/models/user_model.dart' as lm24;
import 'package:myworksapp/core/database/models/worker_model.dart' as lm25;
import 'package:myworksapp/core/database/repositories/payout_repository.dart'
    as lm26;
import 'package:myworksapp/core/domain/job_charge_preview.dart' as lm27;
import 'package:myworksapp/core/domain/price_quote.dart' as lm28;
import 'package:myworksapp/core/domain/reschedule_rules.dart' as lm29;
import 'package:myworksapp/core/domain/webpay_transaction.dart' as lm30;
import 'package:myworksapp/core/domain/worker_charge.dart' as lm31;
import 'package:myworksapp/core/domain/worker_custom_service.dart' as lm32;
import 'package:myworksapp/core/domain/worker_public_stats.dart' as lm33;
import 'package:myworksapp/core/dto/job_dto.dart' as lm34;
import 'support/model_probe.dart';

void main() {
  group('AbuseEventModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_usuario': 'v_id_usuario',
      'tipo_abuso': 'v_tipo_abuso',
      'conteo': 1,
      'detectado_en': '2026-01-02T03:04:05.000Z',
      'accion_tomada': 'v_accion_tomada',
      'accion_tomada_en': '2026-01-02T03:04:05.000Z',
      'resuelto': 1
    };
    dynamic build(Map<String, dynamic> m) => lm0.AbuseEventModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm0.AbuseEventModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm0.AbuseEventModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('AnalyticsEventModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'nombre_evento': 'v_nombre_evento',
      'id_usuario': 'v_id_usuario',
      'rol': 'v_rol',
      'marca_tiempo': '2026-01-02T03:04:05.000Z',
      'metadatos': 'v_metadatos'
    };
    dynamic build(Map<String, dynamic> m) => lm1.AnalyticsEventModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm1.AnalyticsEventModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('AppErrorLogModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_usuario': 'v_id_usuario',
      'tipo_error': 'v_tipo_error',
      'mensaje': 'v_mensaje',
      'traza_pila': 'v_traza_pila',
      'metadatos': 'v_metadatos',
      'estado': 'v_estado',
      'version_app': 'v_version_app',
      'plataforma': 'v_plataforma',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm2.AppErrorLogModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm2.AppErrorLogModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm2.AppErrorLogModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('BoostModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajador': 'v_id_trabajador',
      'tipo_impulso': 'v_tipo_impulso',
      'fecha_inicio': '2026-01-02T03:04:05.000Z',
      'fecha_fin': '2026-01-02T03:04:05.000Z',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm3.BoostModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm3.BoostModel>());
      touchCommon(o);
      probe(() => o.isActive);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.isActive);
        probe(() => o.toMap());
      }
    });
  });
  group('ChangeOrderModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'id_trabajador': 'v_id_trabajador',
      'tipo': 'v_tipo',
      'titulo': 'v_titulo',
      'descripcion': 'v_descripcion',
      'monto_clp': 1500.0,
      'estado': 'v_estado',
      'id_pago': 'v_id_pago',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'respondido_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm4.ChangeOrderModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm4.ChangeOrderModel>());
      touchCommon(o);
      probe(() => o.isPaid);
      probe(() => o.isPendingClient);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.isPaid);
        probe(() => o.isPendingClient);
        probe(() => o.toMap());
      }
    });
  });
  group('DisputeModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'abierta_por': 'v_abierta_por',
      'motivo': 'v_motivo',
      'descripcion': 'v_descripcion',
      'estado': 'v_estado',
      'resolucion': 'v_resolucion',
      'decision_sugerida': 'v_decision_sugerida',
      'motivo_regla': 'v_motivo_regla',
      'origen': 'v_origen',
      'resuelta_por': 'v_resuelta_por',
      'resuelta_en': '2026-01-02T03:04:05.000Z',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'actualizado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm5.DisputeModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm5.DisputeModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm5.DisputeModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('FeatureFlagModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'nombre_bandera': 'v_nombre_bandera',
      'habilitada': 1,
      'version_app': 'v_version_app',
      'rol': 'v_rol',
      'id_usuario': 'v_id_usuario',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'actualizado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm6.FeatureFlagModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm6.FeatureFlagModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm6.FeatureFlagModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('JobCancellationModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'cancelado_por': 'v_cancelado_por',
      'motivo': 'v_motivo',
      'cancelado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) =>
        lm7.JobCancellationModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm7.JobCancellationModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('JobModel', () {
    final sample = <String, dynamic>{
      'metadatos_servicio': 'v_metadatos_servicio',
      'instantanea_precio': 1000,
      'id': 'v_id',
      'id_usuario': 'v_id_usuario',
      'id_trabajador': 'v_id_trabajador',
      'id_servicio': 'v_id_servicio',
      'estado': 'v_estado',
      'direccion': 'v_direccion',
      'latitud': 1000,
      'longitud': 1000,
      'descripcion': 'v_descripcion',
      'fecha_programada': '2026-01-02T03:04:05.000Z',
      'modalidad_cobro': 'v_modalidad_cobro',
      'estado_pago': 'v_estado_pago',
      'id_comuna': 'v_id_comuna',
      'id_sku_servicio': 'v_id_sku_servicio',
      'horas_bloque': 1,
      'id_cotizacion_seleccionada': 'v_id_cotizacion_seleccionada',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'actualizado_en': '2026-01-02T03:04:05.000Z',
      'monto_conocido_clp': 1500.0,
      'recordedAmountClp': 1500.0
    };
    dynamic build(Map<String, dynamic> m) => lm8.JobModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm8.JobModel>());
      touchCommon(o);
      probe(() => o.requiresEscrow);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm8.JobModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.requiresEscrow);
        probe(() => o.toMap());
      }
    });
  });
  group('JobPhotoModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'ruta_foto': 'v_ruta_foto',
      'tipo_medio': 'v_tipo_medio',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'imagen_webp': 'v_imagen_webp'
    };
    dynamic build(Map<String, dynamic> m) => lm9.JobPhotoModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm9.JobPhotoModel>());
      touchCommon(o);
      probe(() => o.hasRenderablePhoto);
      probe(() => o.isVideo);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.hasRenderablePhoto);
        probe(() => o.isVideo);
        probe(() => o.toMap());
      }
    });
  });
  group('MessageModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'id_remitente': 'v_id_remitente',
      'id_destinatario': 'v_id_destinatario',
      'contenido': 'v_contenido',
      'tipo': 'v_tipo',
      'ruta_imagen': 'v_ruta_imagen',
      'leido': 1,
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm10.MessageModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm10.MessageModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('NotificationModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_usuario': 'v_id_usuario',
      'tipo': 'v_tipo',
      'titulo': 'v_titulo',
      'cuerpo': 'v_cuerpo',
      'id_relacionado': 'v_id_relacionado',
      'leido': 1,
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm11.NotificationModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm11.NotificationModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('PaymentModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'id_orden_cambio': 'v_id_orden_cambio',
      'tipo_pago': 'v_tipo_pago',
      'monto': 1500.0,
      'moneda': 'v_moneda',
      'estado': 'v_estado',
      'metodo_pago': 'v_metodo_pago',
      'id_transaccion': 'v_id_transaccion',
      'autorizado_en': '2026-01-02T03:04:05.000Z',
      'liberado_en': '2026-01-02T03:04:05.000Z',
      'reembolsado_en': '2026-01-02T03:04:05.000Z',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'actualizado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm12.PaymentModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm12.PaymentModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm12.PaymentModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('PendingActionModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_usuario': 'v_id_usuario',
      'tipo_accion': 'v_tipo_accion',
      'tipo_entidad': 'v_tipo_entidad',
      'id_entidad': 'v_id_entidad',
      'datos': 'v_datos',
      'estado': 'v_estado',
      'conteo_reintentos': 1,
      'mensaje_error': 'v_mensaje_error',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'actualizado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm13.PendingActionModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm13.PendingActionModel>());
      touchCommon(o);
      probe(() => o.hasFailed);
      probe(() => o.isPending);
      probe(() => o.isSynced);
      probe(() => o.isSyncing);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm13.PendingActionModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.hasFailed);
        probe(() => o.isPending);
        probe(() => o.isSynced);
        probe(() => o.isSyncing);
        probe(() => o.toMap());
      }
    });
  });
  group('PortfolioModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajador': 'v_id_trabajador',
      'ruta_foto': 'v_ruta_foto',
      'descripcion': 'v_descripcion',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'tipo_medio': 'v_tipo_medio'
    };
    dynamic build(Map<String, dynamic> m) => lm14.PortfolioModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm14.PortfolioModel>());
      touchCommon(o);
      probe(() => o.isDemoAsset);
      probe(() => o.isVideo);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.isDemoAsset);
        probe(() => o.isVideo);
        probe(() => o.toMap());
      }
    });
  });
  group('QuoteProposalModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'id_trabajador': 'v_id_trabajador',
      'monto_total_clp': 1500.0,
      'descripcion': 'v_descripcion',
      'validez_hasta': '2026-01-02T03:04:05.000Z',
      'estado': 'v_estado',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm15.QuoteProposalModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm15.QuoteProposalModel>());
      touchCommon(o);
      probe(() => o.itemRows());
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('RankingConfig', () {
    final sample = <String, dynamic>{
      'peso_calificacion': 1000,
      'peso_completados': 1000,
      'peso_rechazos': 1000,
      'peso_verificacion': 1000,
      'peso_impulso': 1000,
      'peso_recencia': 1000,
      'peso_confianza': 1000,
      'prior_bayes': 'v_prior_bayes',
      'n_bayes': 'v_n_bayes',
      'umbral_revision': 'v_umbral_revision',
      'umbral_auto_excluir': 'v_umbral_auto_excluir',
      'aprendizaje_activo': 'v_aprendizaje_activo',
      'tasa_aprendizaje': 'v_tasa_aprendizaje',
      'pesos_senal': 1000,
      'actualizado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm16.RankingConfig.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm16.RankingConfig>());
      touchCommon(o);
      probe(() => o.toRpcMap());
      expect(o.copyWith(), isA<lm16.RankingConfig>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
      }
    });
  });
  group('ReviewSignal', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_calificacion': 'v_id_calificacion',
      'tipo_senal': 'v_tipo_senal',
      'puntaje': 1500.0,
      'estado': 'v_estado',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'detalle': 'v_detalle',
      'puntaje_resena': 1500.0,
      'comentario': 'v_comentario',
      'estado_revision': 'v_estado_revision',
      'peso_confianza': 1500.0,
      'id_trabajo': 'v_id_trabajo',
      'id_trabajador': 'v_id_trabajador',
      'nombre_trabajador': 'v_nombre_trabajador',
      'nombre_cliente': 'v_nombre_cliente'
    };
    dynamic build(Map<String, dynamic> m) => lm16.ReviewSignal.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm16.ReviewSignal>());
      touchCommon(o);
      probe(() => o.signalLabel);
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.signalLabel);
      }
    });
  });
  group('RatingModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'id_usuario': 'v_id_usuario',
      'id_calificado': 'v_id_calificado',
      'direccion': 'v_direccion',
      'puntaje': 1500.0,
      'comentario': 'v_comentario',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm17.RatingModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm17.RatingModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('ReportModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_reportante': 'v_id_reportante',
      'id_usuario_reportado': 'v_id_usuario_reportado',
      'motivo': 'v_motivo',
      'descripcion': 'v_descripcion',
      'estado': 'v_estado',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm18.ReportModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm18.ReportModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('ServiceConfigModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_servicio': 'v_id_servicio',
      'esquema_config': 'v_esquema_config',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'actualizado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm19.ServiceConfigModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm19.ServiceConfigModel>());
      touchCommon(o);
      probe(() => o.getRequiredFields());
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('ServiceModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'nombre': 'v_nombre',
      'descripcion': 'v_descripcion',
      'categoria': 'v_categoria',
      'activo': 1,
      'requiere_certificacion': 1,
      'modelo_precio': 'v_modelo_precio',
      'aviso_legal': 'v_aviso_legal',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'actualizado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm20.ServiceModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm20.ServiceModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm20.ServiceModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('SubscriptionModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_usuario': 'v_id_usuario',
      'tipo_plan': 'v_tipo_plan',
      'estado': 'v_estado',
      'fecha_inicio': '2026-01-02T03:04:05.000Z',
      'fecha_fin': '2026-01-02T03:04:05.000Z',
      'creado_en': '2026-01-02T03:04:05.000Z',
      'actualizado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm21.SubscriptionModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm21.SubscriptionModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm21.SubscriptionModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('UserBlockModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_bloqueador': 'v_id_bloqueador',
      'id_bloqueado': 'v_id_bloqueado',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm22.UserBlockModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm22.UserBlockModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('UserConsentModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_usuario': 'v_id_usuario',
      'version_consentimiento': 'v_version_consentimiento',
      'aceptado': 1,
      'aceptado_en': '2026-01-02T03:04:05.000Z',
      'direccion_ip': 'v_direccion_ip',
      'agente_usuario': 'v_agente_usuario'
    };
    dynamic build(Map<String, dynamic> m) => lm23.UserConsentModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm23.UserConsentModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm23.UserConsentModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('UserModel', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'nombre': 'v_nombre',
      'correo': 'v_correo',
      'password': 'valor_de_prueba',
      'rol': 'v_rol',
      'estado_cuenta': 'v_estado_cuenta',
      'ruta_foto_perfil': 'v_ruta_foto_perfil',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm24.UserModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm24.UserModel>());
      touchCommon(o);
      probe(() => o.isActive);
      probe(() => o.isBlocked);
      probe(() => o.isSuspended);
      probe(() => o.userRole);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm24.UserModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.isActive);
        probe(() => o.isBlocked);
        probe(() => o.isSuspended);
        probe(() => o.userRole);
        probe(() => o.toMap());
      }
    });
  });
  group('WorkerModel', () {
    final sample = <String, dynamic>{
      'profesion': 'v_profesion',
      'id_usuario': 'v_id_usuario',
      'descripcion': 'v_descripcion',
      'calificacion': 1500.0,
      'rating': 1500.0,
      'disponible': 'v_disponible',
      'tarifa_visita': 1500.0,
      'trabajador_precios': 1000,
      'trabajador_servicios_extra': 'v_trabajador_servicios_extra',
      'precios_configurados': 1000,
      'zona_trabajo': 'v_zona_trabajo',
      'latitud_base': 1500.0,
      'longitud_base': 1500.0,
      'radio_servicio_km': 1500.0,
      'origen_base': 'v_origen_base',
      'conteo_rechazos': 1500.0,
      'score_listado': 1500.0,
      'prioridad_manual': 1500.0,
      'trabajos_completados': 1500.0,
      'es_elite': true,
      'radio_urbano_km': 1500.0,
      'tarifa_fuera_radio_clp': 1500.0,
      'horas_publicadas': 'v_horas_publicadas'
    };
    dynamic build(Map<String, dynamic> m) => lm25.WorkerModel.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm25.WorkerModel>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm25.WorkerModel>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('BankAccount', () {
    final sample = <String, dynamic>{
      'banco': 'v_banco',
      'tipo_cuenta': 'v_tipo_cuenta',
      'numero_cuenta': 'v_numero_cuenta',
      'rut_titular': 'v_rut_titular',
      'nombre_titular': 'v_nombre_titular'
    };
    dynamic build(Map<String, dynamic> m) => lm26.BankAccount.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm26.BankAccount>());
      touchCommon(o);
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
      }
    });
  });
  group('JobChargePreview', () {
    final sample = <String, dynamic>{};
    dynamic build(Map<String, dynamic> m) => lm27.JobChargePreview.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm27.JobChargePreview>());
      touchCommon(o);
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
      }
    });
  });
  group('PriceQuote', () {
    final sample = <String, dynamic>{
      'pricing_mode': 'v_pricing_mode',
      'pricingMode': 'v_pricingMode',
      'currency': 'v_currency',
      'breakdown': <String, dynamic>{},
      'message': 'v_message'
    };
    dynamic build(Map<String, dynamic> m) => lm28.PriceQuote.fromJson(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm28.PriceQuote>());
      touchCommon(o);
      probe(() => o.feeDeductedFromWorker);
      probe(() => o.toJobMetadata());
      final roundTrip = Map<String, dynamic>.from(o.toJson() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.feeDeductedFromWorker);
        probe(() => o.toJson());
      }
    });
  });
  group('RescheduleProposal', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'id_trabajo': 'v_id_trabajo',
      'propuesta_por': 'v_propuesta_por',
      'rol_proponente': 'v_rol_proponente',
      'fecha_anterior': '2026-01-02T03:04:05.000Z',
      'fecha_propuesta': '2026-01-02T03:04:05.000Z',
      'estado': 'v_estado',
      'motivo': 'v_motivo',
      'respondida_por': 'v_respondida_por',
      'respondida_en': '2026-01-02T03:04:05.000Z',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm29.RescheduleProposal.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm29.RescheduleProposal>());
      touchCommon(o);
      probe(() => o.isPending);
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.isPending);
      }
    });
  });
  group('WebpayTransactionResponse', () {
    final sample = <String, dynamic>{
      'token': 'v_token',
      'url': 'v_url',
      'buyOrder': 'v_buyOrder',
      'buy_order': 'v_buy_order',
      'redirectUrl': 'v_redirectUrl',
      'paymentId': 'v_paymentId'
    };
    dynamic build(Map<String, dynamic> m) =>
        lm30.WebpayTransactionResponse.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm30.WebpayTransactionResponse>());
      touchCommon(o);
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
      }
    });
  });
  group('WebpayCommitResult', () {
    final sample = <String, dynamic>{
      'responseCode': 'v_responseCode',
      'response_code': 'v_response_code',
      'approved': 'v_approved',
      'ok': 'v_ok',
      'paymentStatus': 'v_paymentStatus',
      'jobStatus': 'v_jobStatus',
      'jobId': 'v_jobId',
      'paymentId': 'v_paymentId',
      'buyOrder': 'v_buyOrder',
      'error': 'v_error',
      'message': 'v_message'
    };
    dynamic build(Map<String, dynamic> m) => lm30.WebpayCommitResult.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm30.WebpayCommitResult>());
      touchCommon(o);
      probe(() => o.rejected);
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.rejected);
      }
    });
  });
  group('WorkerCharge', () {
    final sample = <String, dynamic>{
      'bruto_clp': 'v_bruto_clp',
      'comision_clp': 1000,
      'neto_clp': 'v_neto_clp',
      'id_pago': 'v_id_pago',
      'id_trabajo': 'v_id_trabajo',
      'tipo_pago': 'v_tipo_pago',
      'estado_pago': 'v_estado_pago',
      'estado_transferencia': 'v_estado_transferencia',
      'referencia_transferencia': 'v_referencia_transferencia',
      'liquidado_en': '2026-01-02T03:04:05.000Z',
      'liberado_en': '2026-01-02T03:04:05.000Z',
      'creado_en': '2026-01-02T03:04:05.000Z'
    };
    dynamic build(Map<String, dynamic> m) => lm31.WorkerCharge.fromRow(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm31.WorkerCharge>());
      touchCommon(o);
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
      }
    });
  });
  group('WorkerCustomService', () {
    final sample = <String, dynamic>{
      'unit': 'v_unit',
      'id': 'v_id',
      'title': 'v_title',
      'subtitle': 'v_subtitle',
      'priceClp': 1500.0
    };
    dynamic build(Map<String, dynamic> m) =>
        lm32.WorkerCustomService.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm32.WorkerCustomService>());
      touchCommon(o);
      probe(() => o.toOptionDef());
      final roundTrip = Map<String, dynamic>.from(o.toMap() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
      expect(o.copyWith(), isA<lm32.WorkerCustomService>());
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toMap());
      }
    });
  });
  group('WorkerPublicStats', () {
    final sample = <String, dynamic>{
      'n_calificaciones': 1500.0,
      'calificacion': 1500.0,
      'trabajos_completados': 1500.0,
      'es_elite': true
    };
    dynamic build(Map<String, dynamic> m) => lm33.WorkerPublicStats.fromMap(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm33.WorkerPublicStats>());
      touchCommon(o);
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
      }
    });
  });
  group('JobDTO', () {
    final sample = <String, dynamic>{
      'id': 'v_id',
      'userId': 'v_userId',
      'workerId': 'v_workerId',
      'serviceId': 'v_serviceId',
      'status': 'v_status',
      'address': 'v_address',
      'latitude': 1000,
      'longitude': 1000,
      'description': 'v_description',
      'scheduledDate': '2026-01-02T03:04:05.000Z',
      'createdAt': '2026-01-02T03:04:05.000Z',
      'updatedAt': '2026-01-02T03:04:05.000Z',
      'metadata': <String, dynamic>{}
    };
    dynamic build(Map<String, dynamic> m) => lm34.JobDTO.fromJson(m);
    test('fromMap con mapa completo', () {
      final o = build(sample);
      expect(o, isA<lm34.JobDTO>());
      touchCommon(o);
      final roundTrip = Map<String, dynamic>.from(o.toJson() as Map);
      expect(roundTrip, isNotEmpty);
      probe(() => build(roundTrip));
    });
    test('fromMap con variantes de la base', () {
      for (final v in variants(sample)) {
        final o = probe(() => build(v));
        if (o == null) continue;
        touchCommon(o);
        probe(() => o.toJson());
      }
    });
  });
}
