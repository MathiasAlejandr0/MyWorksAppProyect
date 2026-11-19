import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/charge_mismatch.dart';
import '../domain/price_quote.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../services/pricing_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_error.dart';
import '../utils/clp_format.dart';
import '../utils/error_handler.dart';
import '../utils/transbank_checkout.dart';
import '../../features/payments/presentation/pages/card_enrollment_page.dart';
import 'pricing_quote_card.dart';
import 'saved_card_tile.dart';
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
  late PriceQuote _quote;
  String? _banner;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
  }

  String _errorText(Object e) {
    if (e is AppError) return e.message;
    return ErrorHandler.userMessage(
      e,
      fallback: 'No se pudo iniciar el pago',
    );
  }

  /// El aviso va dentro de la hoja. Un SnackBar del scaffold de atrás
  /// queda tapado hasta que el cliente cierra el cobro.
  void _fail(Object e) {
    final text = _errorText(e);
    final expected = expectedChargeFromMismatch(text);
    if (expected != null && expected != _quote.totalClp) {
      setState(() {
        _quote = PricingService.instance.alignToChargedTotal(_quote, expected);
        _banner =
            'El total quedó en ${const ClpFormat().format(expected)} según la tarifa real. Confirma otra vez para pagar.';
      });
      return;
    }
    setState(() => _banner = text);
  }

  Future<void> _openWebpay(
    String url, {
    String? paymentId,
  }) async {
    if (kIsWeb) {
      await openTransbankCheckout(url);
      return;
    }
    if (!mounted) return;
    final ok = await WebpayWebViewPage.open(
      context,
      paymentUrl: url,
      title: 'Pago Webpay',
      watchOutcome: () => ref
          .read(paymentServiceProvider)
          .webpayCheckoutSettled(paymentId ?? ''),
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
                amount: _quote.totalClp.toDouble(),
                changeOrderId: widget.changeOrderId,
              );
      final url = session.redirectUrl ?? session.url;
      if (!mounted) return;
      await _openWebpay(url, paymentId: session.paymentId);
    } catch (e) {
      if (!mounted) return;
      _fail(e);
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
      _fail(e);
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
        setState(() {
          _banner = 'Debes iniciar sesión para confirmar el pedido';
        });
        return;
      }

      final payments = ref.read(paymentServiceProvider);
      var charge = await payments.chargeSavedCard(
        jobId: widget.jobId,
        amount: _quote.totalClp.toDouble(),
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
          amount: _quote.totalClp.toDouble(),
        );
      }
      if (!mounted) return;
      if (!charge.charged) {
        setState(() {
          _banner =
              'La tarjeta no quedó lista. Puedes pagar este pedido en Transbank sin guardarla.';
        });
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (kIsWeb && !skipWebFallback && mounted) {
        await _payWithoutSavingCard();
        return;
      }
      if (!mounted) return;
      _fail(e);
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
              'Cobro con tarjeta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              const ClpFormat().format(_quote.totalClp),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandOrange,
                  ),
            ),
            if (widget.serviceName != null || widget.workerName != null) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (widget.serviceName != null) widget.serviceName!,
                  if (widget.workerName != null) widget.workerName!,
                ].join(' · '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
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
              quote: _quote,
              workerName: widget.workerName,
              serviceName: widget.serviceName,
            ),
            const SizedBox(height: 16),
            if (widget.changeOrderId == null || widget.changeOrderId!.isEmpty)
              SavedCardTile(
                enabled: !_processing,
                onCardRemoved: _enrollCard,
              ),
            if (_banner != null) ...[
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    _banner!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _processing
                  ? null
                  : (kIsWeb ? _payWithoutSavingCard : _payWithSavedCard),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                minimumSize: const Size.fromHeight(52),
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
                    ? 'Conectando con Transbank…'
                    : kIsWeb
                        ? 'Pagar ahora · ${const ClpFormat().format(_quote.totalClp)}'
                        : 'Pagar con tarjeta · ${const ClpFormat().format(_quote.totalClp)}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _processing
                  ? null
                  : (kIsWeb ? _enrollCard : _payWithoutSavingCard),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
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
