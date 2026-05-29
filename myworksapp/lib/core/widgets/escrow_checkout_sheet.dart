import 'package:flutter/material.dart';

import '../domain/price_quote.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import 'pricing_quote_card.dart';

/// Checkout mock: simula pasarela y autoriza escrow.
class EscrowCheckoutSheet extends StatefulWidget {
  const EscrowCheckoutSheet({
    super.key,
    required this.jobId,
    required this.quote,
    this.workerName,
    this.serviceName,
  });

  final String jobId;
  final PriceQuote quote;
  final String? workerName;
  final String? serviceName;

  static Future<bool> show(
    BuildContext context, {
    required String jobId,
    required PriceQuote quote,
    String? workerName,
    String? serviceName,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: EscrowCheckoutSheet(
          jobId: jobId,
          quote: quote,
          workerName: workerName,
          serviceName: serviceName,
        ),
      ),
    );
    return result == true;
  }

  @override
  State<EscrowCheckoutSheet> createState() => _EscrowCheckoutSheetState();
}

class _EscrowCheckoutSheetState extends State<EscrowCheckoutSheet> {
  String _method = 'card';
  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    try {
      await PaymentService.instance.createPrimaryPayment(
        jobId: widget.jobId,
        quote: widget.quote,
        paymentMethod: _method,
      );
      await PaymentService.instance.authorizePrimaryForJob(widget.jobId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar pago: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pago seguro (demo)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Simulación de pasarela — sin cargo real',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayMedium,
                  ),
            ),
            const SizedBox(height: 16),
            PricingQuoteCard(
              quote: widget.quote,
              workerName: widget.workerName,
              serviceName: widget.serviceName,
            ),
            const SizedBox(height: 16),
            Text('Método de pago', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'card', label: Text('Tarjeta'), icon: Icon(Icons.credit_card)),
                ButtonSegment(value: 'transfer', label: Text('Transfer.'), icon: Icon(Icons.account_balance)),
              ],
              selected: {_method},
              onSelectionChanged: _processing
                  ? null
                  : (s) => setState(() => _method = s.first),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _processing ? null : _pay,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _processing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Pagar y reservar en garantía'),
            ),
            TextButton(
              onPressed: _processing ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
