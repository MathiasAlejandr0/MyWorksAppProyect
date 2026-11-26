// PaymentService contra el backend falso: transiciones de escrow (autorizar,
// retener, liberar, reembolsar), pago principal del trabajo, funciones Edge de
// tarjeta y Webpay con respuestas de error, y mensajes de error de red.
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/pricing_constants.dart';
import 'package:myworksapp/core/services/payment_service.dart';

import 'support/fake_supabase.dart';
import 'support/model_samples.dart';

const _job = 'job-pagos-1';

Map<String, dynamic> _pago(String id, String estado,
        {String tipo = PricingConstants.paymentTypePrimary}) =>
    {
      ...samplePaymentModel,
      'id': id,
      'id_trabajo': _job,
      'tipo_pago': tipo,
      'estado': estado,
    };

Future<Object?> _intenta(Future<Object?> Function() f) async {
  try {
    return await f();
  } catch (e) {
    return e;
  }
}

void main() {
  late FakeBackend b;
  final svc = PaymentService.instance;

  setUp(() async {
    b = await setUpFakeSupabase(signedIn: true);
  });

  group('transiciones de escrow', () {
    test('autorizar: pendiente pasa, otro estado se rechaza', () async {
      b.seed('pagos', [
        _pago('p1', PricingConstants.paymentPending),
        _pago('p2', PricingConstants.paymentReleased),
      ]);
      final ok = await svc.authorizePayment('p1');
      expect(ok.id, 'p1');
      expect(
          await _intenta(() => svc.authorizePayment('p2')), isA<Exception>());
      expect(await _intenta(() => svc.authorizePayment('nada')), isNotNull);
    });

    test('retener solo pagos autorizados', () async {
      b.seed('pagos', [
        _pago('p1', PricingConstants.paymentAuthorized),
        _pago('p2', PricingConstants.paymentPending),
      ]);
      final held = await svc.holdPayment('p1');
      expect(held.id, 'p1');
      expect(await _intenta(() => svc.holdPayment('p2')), isNotNull);
      expect(await _intenta(() => svc.holdPayment('nada')), isNotNull);
      b.failing.add('pagos');
      expect(await _intenta(() => svc.holdPayment('p1')), isNotNull);
    });

    test('liberar y reembolsar por funciones Edge', () async {
      b.seed('pagos', [
        _pago('p1', PricingConstants.paymentAuthorized),
        _pago('p2', PricingConstants.paymentHeld),
        _pago('p3', PricingConstants.paymentReleased),
      ]);
      b.functions['webpay-release'] = (_) => {
            'payment': _pago('p1', PricingConstants.paymentReleased),
          };
      b.functions['webpay-refund'] = (_) => {
            'payment': _pago('p2', PricingConstants.paymentRefunded),
          };
      final rel = await svc.releasePayment('p1', transferRef: 'TRF-1234');
      expect(rel.status, PricingConstants.paymentReleased);
      final ref = await svc.refundPayment('p2');
      expect(ref.status, PricingConstants.paymentRefunded);
      expect(
          await _intenta(() => svc.releasePayment('p3', transferRef: 'TRF-1')),
          isNotNull);
      expect(await _intenta(() => svc.refundPayment('p3')), isNotNull);
      expect(await _intenta(() => svc.releasePayment('nada', transferRef: 'x')),
          isNotNull);
      expect(await _intenta(() => svc.refundPayment('nada')), isNotNull);
      // Referencia corta: el repositorio rechaza antes de llamar a la función.
      expect(await _intenta(() => svc.releasePayment('p1', transferRef: 'x')),
          isNotNull);
      b.failing.add('fn:webpay-refund');
      expect(await _intenta(() => svc.refundPayment('p2')), isNotNull);
    });
  });

  group('pago principal del trabajo', () {
    test('autorizado o retenido sincroniza el trabajo', () async {
      b.seed('trabajos', [
        {...sampleJobModel, 'id': _job},
      ]);
      b.seed('pagos', [_pago('p1', PricingConstants.paymentAuthorized)]);
      final p = await svc.authorizePrimaryForJob(_job);
      expect(p.status, PricingConstants.paymentAuthorized);
    });

    test('pendiente pide completar Webpay y otro estado se rechaza', () async {
      b.seed('pagos', [_pago('p1', PricingConstants.paymentPending)]);
      expect(await _intenta(() => svc.authorizePrimaryForJob(_job)), isNotNull);
      b.seed('pagos', [_pago('p1', PricingConstants.paymentRefunded)]);
      expect(await _intenta(() => svc.authorizePrimaryForJob(_job)), isNotNull);
      b.seed('pagos', []);
      expect(await _intenta(() => svc.authorizePrimaryForJob(_job)), isNotNull);
    });

    test('liberar al completar: sin pago, ya liberado y liberación', () async {
      b.seed('pagos', []);
      expect(await svc.releasePrimaryOnJobCompleted(_job, transferRef: 'TRF-1'),
          isNull);
      b.seed('pagos', [_pago('p1', PricingConstants.paymentReleased)]);
      final ya =
          await svc.releasePrimaryOnJobCompleted(_job, transferRef: 'TRF-1');
      expect(ya?.status, PricingConstants.paymentReleased);
      b.seed('pagos', [_pago('p1', PricingConstants.paymentHeld)]);
      b.functions['webpay-release'] = (_) => {
            'payment': _pago('p1', PricingConstants.paymentReleased),
          };
      final rel = await _intenta(() =>
          svc.releasePrimaryOnJobCompleted(_job, transferRef: 'TRF-1234'));
      expect(rel, isNotNull);
    });
  });

  group('funciones Edge con error', () {
    test('disputa, rechazo y cancelación devuelven error de negocio', () async {
      b.defaultFunction = (_) => {'error': 'operación rechazada'};
      expect(
          await _intenta(() => svc.resolveDisputeFunds(
              disputeId: 'd1', decision: 'liberar', resolution: 'Acuerdo')),
          isNotNull);
      expect(
          await _intenta(() => svc.refundBecauseWorkerRejected(
              jobId: _job, metadata: const {'motivo': 'rechazo'})),
          isNotNull);
      expect(await _intenta(() => svc.refundPrimaryOnCancellation(_job)),
          isNotNull);
    });

    test('fallas de red en tarjeta y Webpay', () async {
      for (final fn in [
        'payment-dispute-resolve',
        'payment-refund-rejected',
        'oneclick-remove',
        'oneclick-restore',
        'oneclick-start',
        'oneclick-charge',
        'webpay-create',
        'webpay-status',
        'webpay-commit',
      ]) {
        b.failing.add('fn:$fn');
      }
      b.defaultFunction = (_) => throw StateError('sin red');
      final calls = <Future<Object?> Function()>[
        () => svc.resolveDisputeFunds(
            disputeId: 'd1', decision: 'reembolsar', resolution: 'Acuerdo'),
        () => svc.refundBecauseWorkerRejected(
            jobId: _job, metadata: const {'motivo': 'rechazo'}),
        () => svc.removeSavedCard(),
        () => svc.restoreReplacedCard(),
        () => svc.startCardEnrollment(),
        () => svc.chargeSavedCard(jobId: _job, amount: 1000),
        () => svc.initiateWebpayPayment(jobId: _job, amount: 1000),
        () => svc.webpayCheckoutSettled('p1'),
        () => svc.confirmWebpayPayment(token: 'tok'),
      ];
      for (final c in calls) {
        await _intenta(c);
      }
    });

    test('validaciones locales de cobro', () async {
      expect(
          await _intenta(() => svc.chargeSavedCard(jobId: ' ', amount: 1000)),
          isNotNull);
      expect(await _intenta(() => svc.chargeSavedCard(jobId: _job, amount: 0)),
          isNotNull);
      expect(
          await _intenta(
              () => svc.initiateWebpayPayment(jobId: ' ', amount: 1000)),
          isNotNull);
      expect(
          await _intenta(
              () => svc.initiateWebpayPayment(jobId: _job, amount: 0)),
          isNotNull);
      expect(await _intenta(() => svc.confirmWebpayPayment(token: '  ')),
          isNotNull);
      expect(await svc.webpayCheckoutSettled('  '), isNull);
    });

    test('respuestas de estado Webpay', () async {
      for (final (estado, esperado) in [
        (PricingConstants.paymentAuthorized, true),
        (PricingConstants.paymentReleased, true),
        (PricingConstants.paymentFailed, false),
        (PricingConstants.paymentRefunded, false),
        (PricingConstants.paymentPending, null),
      ]) {
        b.functions['webpay-status'] = (_) => {
              'payment': {'estado': estado},
            };
        expect(await svc.webpayCheckoutSettled('p1'), esperado);
      }
      b.functions['webpay-status'] = (_) => {'payment': 'no-es-mapa'};
      expect(await svc.webpayCheckoutSettled('p1'), isNull);
      b.functions['webpay-status'] = (_) => 'texto';
      expect(await svc.webpayCheckoutSettled('p1'), isNull);
    });

    test('commit Webpay aprobado, rechazado e inválido', () async {
      b.functions['webpay-commit'] = (_) => {'error': 'rechazada'};
      final r = await svc.confirmWebpayPayment(token: 'tok');
      expect(r.approved, isFalse);
      b.functions['webpay-commit'] = (_) => {
            'approved': true,
            'paymentStatus': 'AUTHORIZED',
          };
      final ok = await svc.confirmWebpayPayment(token: 'tok');
      expect(ok.approved, isTrue);
      b.functions['webpay-commit'] = (_) => [1, 2];
      expect(await _intenta(() => svc.confirmWebpayPayment(token: 'tok')),
          isNotNull);
    });

    test('Webpay create con error de negocio', () async {
      b.functions['webpay-create'] = (_) => {'error': 'monto inválido'};
      expect(
          await _intenta(
              () => svc.initiateWebpayPayment(jobId: _job, amount: 1000)),
          isNotNull);
    });
  });

  test('creación local deshabilitada', () async {
    expect(await _intenta(() => svc.createPayment(jobId: _job, amount: 1)),
        isNotNull);
  });
}
