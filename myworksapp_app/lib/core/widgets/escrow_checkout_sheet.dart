import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/price_quote.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../theme/app_colors.dart';
import '../../features/payments/presentation/pages/card_enrollment_page.dart';
import 'pricing_quote_card.dart';

/// Checkout de la app: cobra la tarjeta inscrita. Si no hay, la pide una vez.
class EscrowCheckoutSheet extends ConsumerStatefulWidget {
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
  ConsumerState<EscrowCheckoutSheet> createState() =>
      _EscrowCheckoutSheetState();
}

class _EscrowCheckoutSheetState extends ConsumerState<EscrowCheckoutSheet> {
  bool _processing = false;

  Future<void> _payWithCard() async {
    setState(() => _processing = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para confirmar el pedido')),
        );
        return;
      }

      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Inscribe la tarjeta en la app. Con esa tarjeta se cobra el pedido.',
            ),
          ),
        );
        return;
      }

      final payments = ref.read(paymentServiceProvider);
      var charge = await payments.chargeSavedCard(
        jobId: widget.jobId,
        amount: widget.quote.totalClp.toDouble(),
      );
      if (!mounted) return;
      if (charge.needsCard) {
        final enrolled = await CardEnrollmentPage.open(context);
        if (!mounted || !enrolled) return;
        charge = await payments.chargeSavedCard(
          jobId: widget.jobId,
          amount: widget.quote.totalClp.toDouble(),
        );
      }
      if (!mounted) return;
      if (!charge.charged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La tarjeta no quedó lista para este cobro.')),
        );
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cobrar la tarjeta: $e')),
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
              'Confirmar pedido',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.brandOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppColors.brandOrange,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se descuenta de la tarjeta inscrita en la app. Si es la primera vez, Transbank la pide una sola vez.',
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
            const SizedBox(height: 16),
            PricingQuoteCard(
              quote: widget.quote,
              workerName: widget.workerName,
              serviceName: widget.serviceName,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _processing ? null : _payWithCard,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _processing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.credit_card),
              label: Text(
                _processing
                    ? 'Conectando…'
                    : 'Confirmar · \$${widget.quote.totalClp}',
              ),
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
