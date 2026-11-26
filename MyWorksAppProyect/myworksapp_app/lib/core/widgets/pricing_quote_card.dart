import 'package:flutter/material.dart';

import '../domain/price_quote.dart';
import '../services/payment_service.dart';
import '../services/pricing_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../utils/clp_format.dart';

/// Resumen del detalle del trabajo. Espera el traslado real y muestra
/// ese monto; no pinta primero la base redondeada del mapa.
class ServerAlignedQuoteCard extends StatefulWidget {
  const ServerAlignedQuoteCard({
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

  @override
  State<ServerAlignedQuoteCard> createState() => _ServerAlignedQuoteCardState();
}

class _ServerAlignedQuoteCardState extends State<ServerAlignedQuoteCard> {
  PriceQuote? _quote;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preview =
        await PaymentService.instance.previewJobCharge(widget.jobId);
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _quote = preview == null
          ? null
          : PricingService.instance.applyServerCharge(widget.quote, preview);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Calculando tarifa y traslado…')),
      );
    }
    if (quote == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No pudimos calcular el total. Ábrelo de nuevo para reintentar.'),
      );
    }
    return PricingQuoteCard(
      quote: quote,
      workerName: widget.workerName,
      serviceName: widget.serviceName,
    );
  }
}

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
    const currency = ClpFormat();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCardOf(
        context,
        accent: AppColors.brandOrange,
      ),
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
            Text('Trabajador: $workerName',
                style: Theme.of(context).textTheme.bodySmall),
          ],
          const Divider(height: 20),
          if (quote.feeDeductedFromWorker) ...[
            ..._workerChargeRows(context, currency, quote),
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
              const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.brandTeal),
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

  List<Widget> _workerChargeRows(
    BuildContext context,
    ClpFormat currency,
    PriceQuote quote,
  ) {
    final lines = PricingService.instance.workerChargeLines(quote);
    return [
      if (lines.serviceClp != null)
        _row(
          context,
          'Tarifa del servicio',
          currency.format(lines.serviceClp!),
        ),
      if (lines.transportClp > 0)
        _row(context, 'Traslado', currency.format(lines.transportClp)),
      if (lines.serviceClp != null) const SizedBox(height: 8),
      _row(
        context,
        'Total a pagar ahora',
        currency.format(lines.totalClp),
        bold: true,
        accent: true,
      ),
      const SizedBox(height: 8),
      _row(
        context,
        'Comisión del servicio',
        '- ${currency.format(lines.feeClp)}',
      ),
      _row(
        context,
        'El profesional recibe',
        currency.format(lines.payoutClp),
      ),
    ];
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
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
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
