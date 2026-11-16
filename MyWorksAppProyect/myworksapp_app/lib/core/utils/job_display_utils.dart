import 'package:intl/intl.dart';

import '../database/models/job_model.dart';
import '../domain/price_quote.dart';
import '../services/job_price.dart';
import 'santiago_time.dart';

/// Textos legibles para listas y tarjetas de trabajos.
class JobDisplayUtils {
  JobDisplayUtils._();

  static String title(JobModel job) {
    final desc = job.description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;

    final meta = job.serviceMetadata;
    final tierLabel = meta?['worker_tier_label'] as String?;
    if (tierLabel != null && tierLabel.isNotEmpty) return tierLabel;

    final snap = job.pricingSnapshot;
    if (snap != null && snap.isNotEmpty) {
      final quote = PriceQuote.fromJson(snap);
      final fromBreakdown = quote.breakdown['worker_tier_label'] as String?;
      if (fromBreakdown != null && fromBreakdown.isNotEmpty) {
        return fromBreakdown;
      }
      if (quote.message != null && quote.message!.isNotEmpty) {
        return quote.message!;
      }
    }

    if (job.serviceSkuId != null && job.serviceSkuId!.startsWith('tier_')) {
      return job.serviceSkuId!.replaceFirst('tier_', '').replaceAll('_', ' ');
    }

    return 'Solicitud de servicio';
  }

  static String? priceLine(JobModel job) {
    final meta = job.serviceMetadata;
    final metaPrice = meta?['worker_tier_price_clp'];
    final squareMeters = meta?['worker_tier_square_meters'];
    final unitRate = meta?['worker_tier_unit_rate_clp'];
    if (metaPrice is num && metaPrice > 0) {
      if (squareMeters is num && squareMeters > 0 && unitRate is num) {
        return '${_formatClp(metaPrice.toInt())} (${squareMeters.toInt()} m² × ${_formatClp(unitRate.toInt())}/m²)';
      }
      return _formatClp(metaPrice.toInt());
    }

    final snap = job.pricingSnapshot;
    if (snap != null && snap.isNotEmpty) {
      final quote = PriceQuote.fromJson(snap);
      if (quote.totalClp > 0) return _formatClp(quote.totalClp);
    }

    final agreed = agreedJobPriceClp(
      pricingSnapshot: job.pricingSnapshot,
      serviceMetadata: job.serviceMetadata,
      recordedAmountClp: job.recordedAmountClp,
    );
    if (agreed != null) return _formatClp(agreed.round());
    return null;
  }

  /// Monto que el profesional ve en la solicitud, sin abrir el detalle.
  static String offeredAmountLabel(JobModel job) {
    final tier = priceLine(job);
    if (tier != null) {
      return tier.replaceFirst('Tarifa referencial:', 'Oferta:');
    }
    final amount = agreedJobPriceClp(
      pricingSnapshot: job.pricingSnapshot,
      serviceMetadata: job.serviceMetadata,
      recordedAmountClp: job.recordedAmountClp,
    );
    if (amount == null) return 'Monto por cotizar';
    return 'Oferta: ${_formatClp(amount.round()).replaceFirst('Tarifa referencial: ', '')}';
  }

  static String dateLine(JobModel job) {
    final scheduled = job.scheduledDate;
    if (scheduled != null) {
      return 'Programado: ${DateFormat('d MMM y · HH:mm', 'es_CL').format(SantiagoTime.wall(scheduled))}';
    }
    return 'Solicitado: ${DateFormat('d MMM y', 'es_CL').format(SantiagoTime.wall(job.createdAt))}';
  }

  static String _formatClp(int amount) {
    final formatted = NumberFormat.currency(
      locale: 'es_CL',
      symbol: r'$',
      decimalDigits: 0,
    ).format(amount);
    return 'Tarifa referencial: $formatted';
  }
}
