import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/domain/price_quote.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/pricing_quote_card.dart';

class JobDetailClientApprovalCard extends StatelessWidget {
  final String jobId;
  final PriceQuote? quote;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const JobDetailClientApprovalCard({
    super.key,
    required this.jobId,
    required this.quote,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.success.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Revisar finalización del trabajo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'El profesional avisó que terminó. Si recibes conforme, se liberan los fondos que ya están retenidos. Si no estás conforme, se abre un ticket y el dinero queda quieto hasta que atención al cliente decida.',
            ),
            if (quote != null) ...[
              const SizedBox(height: 12),
              PricingQuoteCard(quote: quote!),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                context.push(
                  '${AppConstants.routeJobPhotos}/$jobId',
                  extra: false,
                );
              },
              icon: const Icon(Icons.perm_media),
              label: const Text('Ver evidencia (fotos y videos)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check_circle),
              label: const Text('Recibo conforme'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('No estoy conforme'),
            ),
          ],
        ),
      ),
    );
  }
}
