import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

/// Resumen de precios: visita + nota de precio final en sitio.
class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({
    super.key,
    required this.visitFee,
    this.workerName,
    this.serviceName,
  });

  final double visitFee;
  final String? workerName;
  final String? serviceName;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCard(accent: AppColors.primaryLight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de costos',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tarifa de visita', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                currency.format(visitFee),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'El precio final del trabajo se confirma durante la visita, según diagnóstico y materiales.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grayMedium,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}
