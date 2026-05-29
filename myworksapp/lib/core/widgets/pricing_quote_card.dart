import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/price_quote.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

/// Desglose de precio calculado (modalidades de cobro).
class PricingQuoteCard extends StatelessWidget {
  const PricingQuoteCard({
    super.key,
    required this.quote,
    this.workerName,
    this.serviceName,
    this.footerNote,
  });

  final PriceQuote quote;
  final String? workerName;
  final String? serviceName;
  final String? footerNote;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCard(accent: AppColors.brandOrange),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de pago',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (serviceName != null) ...[
            const SizedBox(height: 6),
            Text(serviceName!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (workerName != null) ...[
            Text('Trabajador: $workerName', style: Theme.of(context).textTheme.bodySmall),
          ],
          const Divider(height: 20),
          if (quote.feeDeductedFromWorker) ...[
            _row(context, 'Total a pagar ahora', currency.format(quote.totalClp),
                bold: true, accent: true),
            const SizedBox(height: 8),
            _row(context, 'Comisión del servicio',
                '- ${currency.format(quote.platformFeeClp)}'),
            _row(context, 'El profesional recibe',
                currency.format(quote.workerPayoutClp!)),
          ] else ...[
            _row(context, 'Subtotal', currency.format(quote.subtotalClp)),
            if (quote.platformFeeClp > 0)
              _row(context, 'Comisión del servicio',
                  currency.format(quote.platformFeeClp)),
            const SizedBox(height: 8),
            _row(
              context,
              'Total a pagar ahora',
              currency.format(quote.totalClp),
              bold: true,
              accent: true,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.brandTeal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  footerNote ??
                      'El monto queda en garantía hasta que el trabajo se complete.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grayMedium,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
          if (quote.message != null) ...[
            const SizedBox(height: 6),
            Text(
              quote.message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    bool accent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: (bold
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: accent ? AppColors.brandOrange : null,
            ),
          ),
        ],
      ),
    );
  }
}
