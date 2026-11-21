import 'package:flutter/material.dart';
import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/domain/price_quote.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/job_status_copy.dart';

/// Utilidades puras para la pantalla de detalle de trabajo.
class JobDetailHelpers {
  JobDetailHelpers._();

  static PriceQuote? quoteFromJob(JobModel job) {
    final snap = job.pricingSnapshot;
    if (snap != null && snap.isNotEmpty) {
      final fromSnap = PriceQuote.fromJson(snap);
      if (fromSnap.totalClp > 0) return fromSnap;
    }
    return quoteFromMetadata(job.serviceMetadata, job.pricingMode);
  }

  /// El alta del trabajo borra `instantanea_precio`. El cobro visible queda
  /// en metadatos (`quoted_*` o tarifa publicada del profesional).
  static PriceQuote? quoteFromMetadata(
    Map<String, dynamic>? meta,
    String pricingMode,
  ) {
    if (meta == null || meta.isEmpty) return null;
    final total = _asClp(meta['quoted_total_clp']) ??
        _asClp(meta['worker_tier_price_clp']);
    if (total == null || total <= 0) return null;
    return PriceQuote(
      pricingMode: (meta['quoted_pricing_mode'] as String?) ?? pricingMode,
      totalClp: total,
      subtotalClp: _asClp(meta['quoted_subtotal_clp']) ?? total,
      platformFeeClp: _asClp(meta['quoted_fee_clp']) ?? 0,
      workerPayoutClp: _asClp(meta['quoted_worker_payout_clp']),
      message: meta['quoted_message'] as String?,
    );
  }

  static int? _asClp(dynamic value) {
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool isWorkerTierInvitation(JobModel job) {
    return job.serviceMetadata?['request_type'] == 'worker_tier_invitation';
  }

  static String completionTargetStatus(JobModel job) {
    return PricingConstants.jobAwaitingClientApproval;
  }

  /// Chat entre las partes mientras el pedido está vivo (incluye pendiente
  /// y en camino). No aplica a pagado-sin-abrir, completado ni cancelado.
  static bool canOpenChat(String status) {
    return status == AppConstants.jobStatusPending ||
        status == AppConstants.jobStatusAccepted ||
        status == AppConstants.jobStatusEnRoute ||
        status == AppConstants.jobStatusInProgress ||
        status == PricingConstants.jobAwaitingClientApproval;
  }

  /// Estados en que el trabajo ya terminó: no admite disputas ni acuerdos.
  static const Set<String> closedJobStatuses = {
    AppConstants.jobStatusCompleted,
    AppConstants.jobStatusCancelled,
    AppConstants.jobStatusExpired,
    AppConstants.jobStatusNoShow,
  };

  static bool isJobClosed(String status) => closedJobStatuses.contains(status);

  static bool isDisputeOpen(DisputeModel? dispute) {
    if (dispute == null) return false;
    return dispute.status == AppConstants.disputeStatusOpen ||
        dispute.status == AppConstants.disputeStatusUnderReview ||
        dispute.status == AppConstants.disputeStatusNeedsHuman ||
        dispute.status == AppConstants.disputeStatusRefundPending;
  }

  /// Solo un trabajo en marcha admite una disputa nueva. Un trabajo cerrado
  /// (completado, cancelado, expirado, no asistió) ya liberó o devolvió el
  /// pago; el servidor (`abrir_disputa`) aplica la misma regla.
  static bool canOpenDispute(JobModel job, DisputeModel? dispute) {
    if (isDisputeOpen(dispute)) return false;
    return job.status == AppConstants.jobStatusAccepted ||
        job.status == AppConstants.jobStatusEnRoute ||
        job.status == AppConstants.jobStatusInProgress ||
        job.status == PricingConstants.jobAwaitingClientApproval;
  }

  /// Proponer o responder acuerdos solo mientras la disputa sigue abierta y
  /// el trabajo no se cerró.
  static bool canNegotiateDispute(JobModel job, DisputeModel? dispute) =>
      isDisputeOpen(dispute) && !isJobClosed(job.status);

  /// El cliente cancela desde la disputa solo si él la abrió.
  /// Sin disputa, la cancelación con devolución queda para la entrega en
  /// revisión. Un trabajo en marcha se cierra con acuerdo, no con este botón.
  static bool clientCanCancelRequest({
    required JobModel job,
    required DisputeModel? dispute,
    required String? userId,
  }) {
    if (userId == null || userId != job.userId) return false;
    if (isDisputeOpen(dispute)) return dispute!.openedBy == userId;
    return job.status == PricingConstants.jobAwaitingClientApproval;
  }

  static String agreementTypeLabel(String? type) {
    switch (type) {
      case 'aceptar':
        return 'aceptar la entrega';
      case 'rehacer':
        return 'rehacer el trabajo';
      case 'anular':
        return 'anular y devolver el pago';
      default:
        return type ?? '';
    }
  }

  static Color statusColor(String status) => JobStatusCopy.color(status);

  static String paymentStatusLabel(String status) {
    switch (status) {
      case PricingConstants.paymentPending:
        return 'Pendiente';
      case PricingConstants.paymentAuthorized:
        return 'En garantía';
      case PricingConstants.paymentReleased:
        return 'Liberado al trabajador';
      case PricingConstants.paymentRefunded:
        return 'Reembolsado';
      default:
        return status;
    }
  }

  static IconData statusIcon(String status) => JobStatusCopy.icon(status);

  static String statusText(String status) => JobStatusCopy.label(status);
}
