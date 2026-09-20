import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/price_quote.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_gateway_provider.dart';
import '../services/payment_gateway_port.dart';
import '../theme/app_colors.dart';
import 'pricing_quote_card.dart';
import 'webpay_webview_page.dart';

/// Checkout comercial: Webpay en WebView in-app (sin browser externo).
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
  bool _processing = false;

  Future<void> _payWithWebpay() async {
    setState(() => _processing = true);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para pagar con Webpay'),
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
              hold.message ?? 'No se pudo iniciar Webpay',
            ),
          ),
        );
        return;
      }

      final url = hold.redirectUrl;
      if (url != null && url.isNotEmpty) {
        if (!mounted) return;
        final paid = await WebpayWebViewPage.open(
          context,
          paymentUrl: url,
        );
        if (!mounted) return;
        Navigator.of(context).pop(paid);
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar pago: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const integration = !kReleaseMode ||
        String.fromEnvironment('PAYMENTS_MODE', defaultValue: 'integration') !=
            'production';

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
              'Pago con Webpay',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.brandOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppColors.brandOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        integration
                            ? 'Ambiente de integración Transbank — pagas dentro de la app'
                            : 'Pago protegido con Webpay Plus — sin salir a otro navegador',
                        style: const TextStyle(
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
              onPressed: _processing ? null : _payWithWebpay,
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
                    : 'Pagar con Webpay · \$${widget.quote.totalClp}',
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
