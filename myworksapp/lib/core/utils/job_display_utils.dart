import 'package:intl/intl.dart';

import '../database/models/job_model.dart';
import '../domain/price_quote.dart';

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
      final fromBreakdown =
          quote.breakdown['worker_tier_label'] as String?;
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
    if (metaPrice is num && metaPrice > 0) {
      return _formatClp(metaPrice.toInt());
    }

    final snap = job.pricingSnapshot;
    if (snap != null && snap.isNotEmpty) {
      final quote = PriceQuote.fromJson(snap);
      if (quote.totalClp > 0) return _formatClp(quote.totalClp);
    }

    return null;
  }

  static String dateLine(JobModel job) {
    final scheduled = job.scheduledDate;
    if (scheduled != null) {
      return 'Programado: ${DateFormat('d MMM y · HH:mm', 'es_CL').format(scheduled)}';
    }
    return 'Solicitado: ${DateFormat('d MMM y', 'es_CL').format(job.createdAt)}';
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
