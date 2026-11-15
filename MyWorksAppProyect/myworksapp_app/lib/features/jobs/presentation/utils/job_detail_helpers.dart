import 'package:flutter/material.dart';
import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/domain/price_quote.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';

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

  static bool canOpenDispute(JobModel job, DisputeModel? dispute) {
    if (dispute != null &&
        (dispute.status == AppConstants.disputeStatusOpen ||
            dispute.status == AppConstants.disputeStatusUnderReview ||
            dispute.status == AppConstants.disputeStatusNeedsHuman ||
            dispute.status == AppConstants.disputeStatusRefundPending)) {
      return false;
    }
    return job.status == AppConstants.jobStatusAccepted ||
        job.status == AppConstants.jobStatusEnRoute ||
        job.status == AppConstants.jobStatusInProgress ||
        job.status == PricingConstants.jobAwaitingClientApproval ||
        job.status == AppConstants.jobStatusCompleted;
  }

  static Color statusColor(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return AppColors.warning;
      case AppConstants.jobStatusAccepted:
        return AppColors.brandOrange;
      case AppConstants.jobStatusEnRoute:
        return AppColors.brandOrange;
      case AppConstants.jobStatusInProgress:
        return AppColors.brandOrangeDark;
      case AppConstants.jobStatusCompleted:
        return AppColors.success;
      case AppConstants.jobStatusCancelled:
        return AppColors.error;
      case PricingConstants.jobAwaitingPayment:
        return AppColors.brandOrangeDark;
      case PricingConstants.jobAwaitingQuotes:
        return AppColors.warning;
      case PricingConstants.jobQuoteSelected:
        return AppColors.brandOrange;
      case PricingConstants.jobPausedChangeOrder:
        return AppColors.brandOrangeDark;
      case PricingConstants.jobAwaitingClientApproval:
        return AppColors.brandOrange;
      default:
        return AppColors.grayMedium;
    }
  }

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

  static IconData statusIcon(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Icons.pending;
      case AppConstants.jobStatusAccepted:
        return Icons.check_circle_outline;
      case AppConstants.jobStatusEnRoute:
        return Icons.directions_car_outlined;
      case AppConstants.jobStatusInProgress:
        return Icons.work;
      case AppConstants.jobStatusCompleted:
        return Icons.check_circle;
      case AppConstants.jobStatusCancelled:
        return Icons.cancel;
      case PricingConstants.jobAwaitingPayment:
        return Icons.payment;
      case PricingConstants.jobAwaitingQuotes:
        return Icons.request_quote;
      case PricingConstants.jobQuoteSelected:
        return Icons.fact_check;
      case PricingConstants.jobPausedChangeOrder:
        return Icons.pause_circle;
      case PricingConstants.jobAwaitingClientApproval:
        return Icons.rate_review;
      default:
        return Icons.help_outline;
    }
  }

  static String statusText(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return 'Pendiente';
      case AppConstants.jobStatusAccepted:
        return 'Aceptado';
      case AppConstants.jobStatusEnRoute:
        return 'En camino';
      case AppConstants.jobStatusInProgress:
        return 'En Curso';
      case AppConstants.jobStatusCompleted:
        return 'Completado';
      case AppConstants.jobStatusCancelled:
        return 'Cancelado';
      case PricingConstants.jobAwaitingPayment:
        return 'Pago pendiente';
      case PricingConstants.jobAwaitingQuotes:
        return 'Esperando cotizaciones';
      case PricingConstants.jobQuoteSelected:
        return 'Cotización seleccionada';
      case PricingConstants.jobPausedChangeOrder:
        return 'Cobro extra pendiente';
      case PricingConstants.jobAwaitingClientApproval:
        return 'Pendiente de aprobación';
      default:
        return status;
    }
  }
}
