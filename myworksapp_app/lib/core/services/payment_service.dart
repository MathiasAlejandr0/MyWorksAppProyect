import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/repositories/payment_repository.dart';
import '../database/supabase_db.dart';
import '../domain/webpay_transaction.dart';
import '../database/repositories/job_repository.dart';
import '../database/models/payment_model.dart';
import '../domain/pricing_constants.dart';
import '../domain/price_quote.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Servicio de pagos — escrow vía Webpay (Edge) + RPCs admin.
///
/// Crear intención: Edge `webpay-create` / RPC `crear_intencion_pago`.
/// Autorizar: `webpay-commit` (servidor).
/// Liberar/reembolsar: `liberar_escrow` / `reembolsar_escrow` (admin).
class PaymentService {
  PaymentService({
    PaymentRepository? paymentRepository,
    JobRepository? jobRepository,
  })  : _paymentRepository = paymentRepository ?? PaymentRepository(),
        _jobRepository = jobRepository ?? JobRepository();

  static final PaymentService instance = PaymentService();

  final PaymentRepository _paymentRepository;
  final JobRepository _jobRepository;

  /// Crea un pago para un job (MOCK)
  /// 
  /// En producción, esto autorizaría el pago en la pasarela.
  Future<PaymentModel> createPayment({
    required String jobId,
    required double amount,
    String currency = 'CLP',
    String? paymentMethod,
  }) async {
    throw AppError.validation(
      'Usa Webpay (TransbankWebpayGateway) para crear pagos. Insert directo deshabilitado.',
    );
  }

  /// Autoriza un pago (MOCK)
  /// 
  /// En producción, esto autorizaría el pago en la pasarela (escrow).
  Future<PaymentModel> authorizePayment(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (payment.status != PricingConstants.paymentPending) {
        throw AppError.validation('El pago ya fue procesado');
      }

      final updated = payment.copyWith(
        status: PricingConstants.paymentAuthorized,
        authorizedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final persisted = await _paymentRepository.transitionPaymentStatus(
        paymentId: paymentId,
        newStatus: PricingConstants.paymentAuthorized,
      );

      AppLogger.i('Pago autorizado (MOCK): $paymentId');
      return persisted.copyWith(
        authorizedAt: updated.authorizedAt ?? persisted.authorizedAt,
      );
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error autorizando pago', e);
      throw AppError.database('Error al autorizar pago: ${e.toString()}');
    }
  }

  /// Retiene un pago (por disputa)
  Future<PaymentModel> holdPayment(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (payment.status != PricingConstants.paymentAuthorized) {
        throw AppError.validation('Solo se pueden retener pagos autorizados');
      }

      final persisted = await _paymentRepository.transitionPaymentStatus(
        paymentId: paymentId,
        newStatus: PricingConstants.paymentHeld,
      );

      AppLogger.i('Pago retenido: $paymentId');
      return persisted;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error reteniendo pago', e);
      throw AppError.database('Error al retener pago: ${e.toString()}');
    }
  }

  /// Atención al cliente cierra la disputa liberando el pago o devolviéndolo a la tarjeta.
  Future<void> resolveDisputeFunds({
    required String disputeId,
    required String decision,
    required String resolution,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'webpay-resolve-dispute',
        body: {
          'disputeId': disputeId,
          'decision': decision,
          'resolution': resolution,
        },
      );
      final data = _asMap(response.data);
      if (data['error'] != null) {
        throw AppError.validation(data['error'].toString());
      }
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error cerrando disputa', e);
      throw AppError.network(_edgeErrorMessage(e), e);
    }
  }

  /// El profesional rechaza un pendiente con pago retenido: vuelve a la tarjeta.
  Future<void> refundBecauseWorkerRejected({
    required String jobId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'webpay-refund-rejection',
        body: {
          'jobId': jobId,
          'metadata': metadata,
        },
      );
      final data = _asMap(response.data);
      if (data['error'] != null) {
        throw AppError.validation(data['error'].toString());
      }
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error reembolsando rechazo', e);
      throw AppError.network(_edgeErrorMessage(e), e);
    }
  }

  /// Libera un pago al trabajador (liquidación manual con referencia bancaria).
  Future<PaymentModel> releasePayment(
    String paymentId, {
    required String transferRef,
    String? notes,
  }) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (![PricingConstants.paymentAuthorized, PricingConstants.paymentHeld]
          .contains(payment.status)) {
        throw AppError.validation('El pago no puede ser liberado desde este estado');
      }

      final persisted = await _paymentRepository.transitionPaymentStatus(
        paymentId: paymentId,
        newStatus: PricingConstants.paymentReleased,
        transferRef: transferRef,
        notes: notes,
      );

      AppLogger.i('Pago liberado: $paymentId');
      return persisted;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error liberando pago', e);
      throw AppError.database('Error al liberar pago: ${e.toString()}');
    }
  }

  /// Reembolsa un pago
  Future<PaymentModel> refundPayment(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        throw AppError.notFound('Pago no encontrado');
      }

      if (![PricingConstants.paymentAuthorized, PricingConstants.paymentHeld]
          .contains(payment.status)) {
        throw AppError.validation('El pago no puede ser reembolsado desde este estado');
      }

      final persisted = await _paymentRepository.transitionPaymentStatus(
        paymentId: paymentId,
        newStatus: PricingConstants.paymentRefunded,
      );

      AppLogger.i('Pago reembolsado: $paymentId');
      return persisted;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error reembolsando pago', e);
      throw AppError.database('Error al reembolsar pago: ${e.toString()}');
    }
  }

  /// Pago principal del job (escrow).
  Future<PaymentModel?> getPrimaryPayment(String jobId) async {
    try {
      return await _paymentRepository.getPrimaryByJobId(jobId);
    } catch (e) {
      AppLogger.e('Error obteniendo pago del job', e);
      return null;
    }
  }

  Future<PaymentModel?> getPaymentByJobId(String jobId) => getPrimaryPayment(jobId);

  /// Pago adicional (orden de cambio) — solo vía Webpay Edge.
  Future<PaymentModel> createSupplementalPayment({
    required String jobId,
    required String changeOrderId,
    required String paymentType,
    required PriceQuote quote,
    String? paymentMethod,
  }) async {
    throw AppError.validation(
      'Órdenes de cambio: pagar con Webpay (webpay-create). Insert local deshabilitado.',
    );
  }

  /// Crea checkout del pago principal a partir de [PriceQuote].
  Future<PaymentModel> createPrimaryPayment({
    required String jobId,
    required PriceQuote quote,
    String? paymentMethod,
  }) async {
    throw AppError.validation(
      'El pago principal se crea vía Webpay (webpay-create), no localmente.',
    );
  }

  /// Confirma escrow tras Webpay (Edge ya escribió estado) o lee estado actual.
  Future<PaymentModel> authorizePrimaryForJob(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) {
      throw AppError.notFound('No hay pago principal para este trabajo');
    }
    if (payment.status == PricingConstants.paymentAuthorized ||
        payment.status == PricingConstants.paymentHeld) {
      await _syncJobPaymentStatus(jobId, payment.status);
      return payment;
    }
    if (payment.status != PricingConstants.paymentPending) {
      throw AppError.validation('El pago ya fue procesado');
    }
    // Esperar confirmación Webpay (no simular transición local).
    throw AppError.validation(
      'Completa el pago en Webpay. El estado se actualizará al volver de Transbank.',
    );
  }

  /// Libera fondos al completar el trabajo (requiere referencia de transferencia).
  Future<PaymentModel?> releasePrimaryOnJobCompleted(
    String jobId, {
    required String transferRef,
    String? notes,
  }) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) return null;
    if (payment.status == PricingConstants.paymentReleased) return payment;
    final released = await releasePayment(
      payment.id,
      transferRef: transferRef,
      notes: notes,
    );
    await _syncJobPaymentStatus(jobId, PricingConstants.paymentReleased);
    return released;
  }

  Future<void> refundPrimaryOnCancellation(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    if (payment == null) return;
    if ([PricingConstants.paymentAuthorized, PricingConstants.paymentHeld]
        .contains(payment.status)) {
      final response = await supabase.functions.invoke(
        'webpay-refund-cancellation',
        body: {'jobId': jobId},
      );
      final data = _asMap(response.data);
      if (data['error'] != null) {
        throw AppError.validation(data['error'].toString());
      }
      if (data['skipped'] == true) return;
      await _syncJobPaymentStatus(jobId, PricingConstants.paymentRefunded);
    }
  }

  Future<void> _syncJobPaymentStatus(String jobId, String paymentStatus) async {
    if (paymentStatus.isEmpty) return;
    await _jobRepository.syncPaymentStatusFromLedger(jobId);
  }

  /// Verifica si un job tiene pago principal autorizado (garantía).
  Future<bool> hasAuthorizedPrimaryPayment(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    return payment != null &&
        PricingConstants.isEscrowSecured(payment.status);
  }

  Future<bool> hasPayment(String jobId) async {
    final payment = await getPrimaryPayment(jobId);
    return payment != null;
  }

  Future<bool> hasSavedCard() async {
    final sessionId = supabase.auth.currentUser?.id;
    if (sessionId == null || sessionId.isEmpty) return false;
    final response = await supabase.functions.invoke(
      'oneclick-charge',
      body: {'action': 'status'},
    );
    final data = _asMap(response.data);
    if (data['error'] != null) {
      throw AppError.validation(data['error'].toString());
    }
    return data['enrolled'] == true;
  }

  /// Primera vez en la app: URL del servidor que abre Transbank. Vacía si ya hay tarjeta.
  Future<String> startCardEnrollment() async {
    final sessionId = supabase.auth.currentUser?.id;
    if (sessionId == null || sessionId.isEmpty) {
      throw AppError.authentication('Debes iniciar sesión para guardar la tarjeta');
    }
    try {
      final response = await supabase.functions.invoke(
        'oneclick-charge',
        body: {'action': 'enroll'},
      );
      final data = _asMap(response.data);
      if (data['error'] != null) {
        throw AppError.validation(data['error'].toString());
      }
      if (data['enrolled'] == true) return '';
      final handoff = data['handoffUrl']?.toString() ?? '';
      if (!handoff.startsWith('https://')) {
        throw AppError.validation('No se pudo iniciar la inscripción de la tarjeta');
      }
      return handoff;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error inscribiendo tarjeta', e);
      throw AppError.network(_edgeErrorMessage(e), e);
    }
  }

  /// Cobra la tarjeta Oneclick ya inscrita.
  /// Si todavía no hay tarjeta, [needsCard] pide inscribirla en la app.
  Future<({bool charged, bool needsCard})> chargeSavedCard({
    required String jobId,
    required double amount,
  }) async {
    if (jobId.trim().isEmpty) {
      throw AppError.validation('Falta el identificador del trabajo');
    }
    if (amount <= 0) {
      throw AppError.validation('El monto a pagar debe ser mayor a cero');
    }
    final sessionId = supabase.auth.currentUser?.id;
    if (sessionId == null || sessionId.isEmpty) {
      throw AppError.authentication('Debes iniciar sesión para pagar');
    }

    try {
      final response = await supabase.functions.invoke(
        'oneclick-charge',
        body: {
          'jobId': jobId,
          'amountClp': amount.round(),
        },
      );
      final data = _asMap(response.data);
      if (data['error'] != null) {
        throw AppError.validation(data['error'].toString());
      }
      if (data['charged'] == true) {
        return (charged: true, needsCard: false);
      }
      if (data['needsCard'] == true) {
        return (charged: false, needsCard: true);
      }
      throw AppError.validation('Respuesta de pago inválida');
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error cobrando tarjeta', e);
      throw AppError.network(_edgeErrorMessage(e), e);
    }
  }

  /// Abre Webpay Plus por `webpay-create` (handoff, sin token al cliente).
  Future<WebpayTransactionResponse> initiateWebpayPayment({
    required String jobId,
    required double amount,
  }) async {
    if (jobId.trim().isEmpty) {
      throw AppError.validation('Falta el identificador del trabajo');
    }
    if (amount <= 0) {
      throw AppError.validation('El monto a pagar debe ser mayor a cero');
    }
    final sessionId = supabase.auth.currentUser?.id;
    if (sessionId == null || sessionId.isEmpty) {
      throw AppError.authentication('Debes iniciar sesión para pagar');
    }

    try {
      final response = await supabase.functions.invoke(
        'webpay-create',
        body: {
          'jobId': jobId,
          'amountClp': amount.round(),
          'returnUrl': _webpayClientReturn(),
        },
      );
      final data = _asMap(response.data);
      if (data['error'] != null) {
        throw AppError.validation(data['error'].toString());
      }
      return WebpayTransactionResponse.fromMap(data);
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error iniciando Webpay', e);
      throw AppError.network(_edgeErrorMessage(e), e);
    }
  }

  /// Confirma `token_ws` en `webpay-commit`.
  Future<WebpayCommitResult> confirmWebpayPayment({
    required String token,
  }) async {
    final tokenWs = token.trim();
    if (tokenWs.isEmpty) {
      throw AppError.validation('token_ws ausente');
    }
    try {
      final response = await supabase.functions.invoke(
        'webpay-commit',
        body: {'token_ws': tokenWs},
      );
      final data = _asMap(response.data);
      if (data['error'] != null && data['approved'] != true) {
        return WebpayCommitResult(
          approved: false,
          paymentStatus: 'REJECTED',
          message: data['error'].toString(),
        );
      }
      return WebpayCommitResult.fromMap(data);
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.e('Error confirmando Webpay', e);
      throw AppError.network(_edgeErrorMessage(e), e);
    }
  }

  String _webpayClientReturn() {
    if (kIsWeb) return '${Uri.base.origin}/payment-result';
    return 'myworksapp://payment-result';
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw AppError.validation('Respuesta inválida de Webpay');
  }

  String _edgeErrorMessage(Object error) {
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        return details['error'].toString();
      }
      if (details is String && details.isNotEmpty) return details;
      return error.reasonPhrase ?? 'No se pudo contactar a Webpay';
    }
    if (error is FormatException) return error.message;
    return 'No se pudo contactar a Webpay';
  }
}

