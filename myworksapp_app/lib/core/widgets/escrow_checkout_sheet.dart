import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/price_quote.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_gateway_provider.dart';
import '../providers/service_providers.dart';
import '../services/payment_gateway_port.dart';
import '../theme/app_colors.dart';
import 'pricing_quote_card.dart';

/// Checkout mock: simula pasarela y autoriza escrow.
class EscrowCheckoutSheet extends ConsumerStatefulWidget {
  const EscrowCheckoutSheet({
    super.key,
    required this.jobId,
    required this.quote,
    this.workerName,
    this.serviceName,
    this.gateway,
  });

  final String jobId;
  final PriceQuote quote;
  final String? workerName;
  final String? serviceName;

  /// Override opcional (tests); si es null se usa [paymentGatewayProvider].
  final PaymentGatewayPort? gateway;

  static Future<bool> show(
    BuildContext context, {
    required String jobId,
    required PriceQuote quote,
    String? workerName,
    String? serviceName,
    PaymentGatewayPort? gateway,
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
          gateway: gateway,
        ),
      ),
    );
    return result == true;
  }

  @override
  ConsumerState<EscrowCheckoutSheet> createState() =>
      _EscrowCheckoutSheetState();
}

class _EscrowCheckoutSheetState extends ConsumerState<EscrowCheckoutSheet> {
  String _method = 'card';
  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debes iniciar sesión para completar el pago en garantía',
            ),
          ),
        );
        return;
      }

      final PaymentGatewayPort gateway =
          widget.gateway ?? ref.read(paymentGatewayProvider);
      final hold = await gateway.authorizeHold(
        jobId: widget.jobId,
        amountClp: widget.quote.totalClp,
        userId: user.id,
      );

      if (!hold.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hold.message ?? 'No se pudo autorizar el hold de pago',
            ),
          ),
        );
        return;
      }

      final payments = ref.read(paymentServiceProvider);
      await payments.createPrimaryPayment(
        jobId: widget.jobId,
        quote: widget.quote,
        paymentMethod: _method,
      );
      await payments.authorizePrimaryForJob(widget.jobId);
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
            const SizedBox(height: 8),
            Material(
              color: AppColors.brandOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.brandOrange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pago simulado (MockPaymentGateway) — sin pasarela real',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandOrange,
                        ),
                      ),
                    ),
                  ],
                ),
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
                ButtonSegment(
                  value: 'card',
                  label: Text('Tarjeta'),
                  icon: Icon(Icons.credit_card),
                ),
                ButtonSegment(
                  value: 'transfer',
                  label: Text('Transfer.'),
                  icon: Icon(Icons.account_balance),
                ),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Pagar y reservar en garantía'),
            ),
            TextButton(
              onPressed:
                  _processing ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
