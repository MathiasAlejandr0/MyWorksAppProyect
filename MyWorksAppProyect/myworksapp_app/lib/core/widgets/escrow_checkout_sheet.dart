import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/price_quote.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../theme/app_colors.dart';
import '../utils/app_error.dart';
import '../utils/transbank_checkout.dart';
import '../../features/payments/presentation/pages/card_enrollment_page.dart';
import 'pricing_quote_card.dart';
import 'webpay_webview_page.dart';

/// Checkout: pagar este pedido en Transbank, o inscribir tarjeta y cobrarla.
class EscrowCheckoutSheet extends ConsumerStatefulWidget {
  const EscrowCheckoutSheet({
    super.key,
    required this.jobId,
    required this.quote,
    this.workerName,
    this.serviceName,
    this.changeOrderId,
  });

  final String jobId;
  final PriceQuote quote;
  final String? workerName;
  final String? serviceName;
  final String? changeOrderId;

  static Future<bool> show(
    BuildContext context, {
    required String jobId,
    required PriceQuote quote,
    String? workerName,
    String? serviceName,
    String? changeOrderId,
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
          changeOrderId: changeOrderId,
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

  String _errorText(Object e) {
    if (e is AppError) return e.message;
    return 'No se pudo iniciar el pago';
  }

  Future<void> _openWebpay(String url) async {
    if (kIsWeb) {
      await openTransbankCheckout(url);
      return;
    }
    if (!mounted) return;
    final ok = await WebpayWebViewPage.open(
      context,
      paymentUrl: url,
      title: 'Pago Webpay',
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _payWithoutSavingCard() async {
    setState(() => _processing = true);
    try {
      final session =
          await ref.read(paymentServiceProvider).initiateWebpayPayment(
                jobId: widget.jobId,
                amount: widget.quote.totalClp.toDouble(),
                changeOrderId: widget.changeOrderId,
              );
      final url = session.redirectUrl ?? session.url;
      if (!mounted) return;
      await _openWebpay(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _enrollCard() async {
    setState(() => _processing = true);
    try {
      final enrolled = await CardEnrollmentPage.open(context);
      if (!mounted) return;
      if (!enrolled) return;
      await _payWithSavedCard(skipWebFallback: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _payWithSavedCard({bool skipWebFallback = false}) async {
    // Órdenes de cambio solo por Webpay Plus (RPC dedicado).
    if (widget.changeOrderId != null && widget.changeOrderId!.isNotEmpty) {
      await _payWithoutSavingCard();
      return;
    }
    setState(() => _processing = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para confirmar el pedido'),
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
        if (kIsWeb && !skipWebFallback) {
          await _payWithoutSavingCard();
          return;
        }
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
          const SnackBar(
            content: Text(
              'La tarjeta no quedó lista. Puedes pagar este pedido en Transbank sin guardarla.',
            ),
          ),
        );
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (kIsWeb && !skipWebFallback && mounted) {
        await _payWithoutSavingCard();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        kIsWeb
                            ? 'Primera confirmación: el monto queda retenido en Transbank. Se libera solo cuando recibas conforme el trabajo.'
                            : 'Primera confirmación: el monto queda retenido. Se libera solo cuando recibas conforme el trabajo.',
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
              onPressed: _processing
                  ? null
                  : (kIsWeb ? _payWithoutSavingCard : _payWithSavedCard),
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
                  : const Icon(Icons.lock_outline),
              label: Text(
                _processing
                    ? 'Conectando con Transbank…'
                    : kIsWeb
                        ? 'Pagar ahora en Transbank · \$${widget.quote.totalClp}'
                        : 'Pagar con tarjeta · \$${widget.quote.totalClp}',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _processing
                  ? null
                  : (kIsWeb ? _enrollCard : _payWithoutSavingCard),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(kIsWeb ? Icons.add_card : Icons.account_balance),
              label: const Text(
                kIsWeb
                    ? 'Inscribir tarjeta en Transbank'
                    : 'Pagar en Transbank sin guardar tarjeta',
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
