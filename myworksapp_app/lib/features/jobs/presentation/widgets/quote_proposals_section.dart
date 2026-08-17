import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/models/quote_proposal_model.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Lista de cotizaciones para modalidad open_quote.
class QuoteProposalsSection extends StatelessWidget {
  const QuoteProposalsSection({
    super.key,
    required this.proposals,
    required this.isClient,
    required this.jobStatus,
    this.onSelect,
    this.onSubmitQuote,
  });

  final List<QuoteProposalModel> proposals;
  final bool isClient;
  final String jobStatus;
  final void Function(QuoteProposalModel proposal)? onSelect;
  final VoidCallback? onSubmitQuote;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final canSubmit = !isClient &&
        jobStatus == PricingConstants.jobAwaitingQuotes &&
        onSubmitQuote != null;
    final canSelect = isClient &&
        jobStatus == PricingConstants.jobAwaitingQuotes &&
        onSelect != null;
    final submitted = proposals
        .where((p) => p.estado == PricingConstants.quoteSubmitted)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Propuestas de cotización', style: Theme.of(context).textTheme.titleLarge),
            if (canSubmit)
              FilledButton.icon(
                onPressed: onSubmitQuote,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Responder cotización'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isClient && submitted.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                jobStatus == PricingConstants.jobAwaitingQuotes
                    ? 'Aún no hay respuesta. El profesional está evaluando materiales, mano de obra y tiempo; te avisaremos cuando envíe su propuesta.'
                    : 'No hay propuestas activas en este estado.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        if (!isClient && submitted.isEmpty && canSubmit)
          Card(
            color: AppColors.brandTeal.withValues(alpha: 0.06),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'El cliente espera tu cotización. Incluye materiales, mano de obra, horas y alcance del trabajo.',
              ),
            ),
          ),
        ...proposals.map((p) => _ProposalCard(
              proposal: p,
              currency: currency,
              canSelect: canSelect && p.estado == PricingConstants.quoteSubmitted,
              onSelect: onSelect,
            )),
      ],
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.currency,
    required this.canSelect,
    this.onSelect,
  });

  final QuoteProposalModel proposal;
  final NumberFormat currency;
  final bool canSelect;
  final void Function(QuoteProposalModel proposal)? onSelect;

  @override
  Widget build(BuildContext context) {
    final d = proposal.desglose;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              currency.format(proposal.montoTotalClp),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandNavy,
                  ),
            ),
            if (d != null) ...[
              const SizedBox(height: 8),
              if (d['materiales_clp'] != null)
                _line('Materiales', currency.format(d['materiales_clp'])),
              if (d['mano_obra_clp'] != null)
                _line('Mano de obra', currency.format(d['mano_obra_clp'])),
              if (d['horas_estimadas'] != null)
                _line('Tiempo estimado', '${d['horas_estimadas']} h'),
            ],
            const SizedBox(height: 8),
            Text(
              proposal.descripcion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 4),
            Text(
              'Estado: ${_estadoLabel(proposal.estado)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.grayMedium,
                  ),
            ),
            if (canSelect && onSelect != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => onSelect!(proposal),
                child: const Text('Aceptar cotización y continuar al pago'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case PricingConstants.quoteSubmitted:
        return 'Enviada — pendiente de tu respuesta';
      case PricingConstants.quoteAccepted:
        return 'Aceptada por el cliente';
      case PricingConstants.quoteRejected:
        return 'No seleccionada';
      case PricingConstants.quoteWithdrawn:
        return 'Retirada';
      default:
        return estado;
    }
  }
}
