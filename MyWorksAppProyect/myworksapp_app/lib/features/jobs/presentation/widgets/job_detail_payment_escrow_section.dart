import 'package:flutter/material.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/quote_proposal_model.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/widgets/pricing_quote_card.dart';
import '../utils/job_detail_helpers.dart';
import 'job_detail_client_approval_card.dart';
import 'open_quote_status_banner.dart';

/// Estado de pago, cotización abierta, escrow y aprobación de finalización.
class JobDetailPaymentEscrowSection extends StatelessWidget {
  final JobModel job;
  final String jobId;
  final bool isWorker;
  final bool isClientOwner;
  final bool isAssignedWorker;
  final String? invitedWorkerName;
  final List<QuoteProposalModel> quoteProposals;
  final VoidCallback onPayEscrow;
  final VoidCallback onApproveCompletion;
  final VoidCallback onRejectCompletion;

  const JobDetailPaymentEscrowSection({
    super.key,
    required this.job,
    required this.jobId,
    required this.isWorker,
    required this.isClientOwner,
    required this.isAssignedWorker,
    required this.invitedWorkerName,
    required this.quoteProposals,
    required this.onPayEscrow,
    required this.onApproveCompletion,
    required this.onRejectCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (job.pricingMode != PricingConstants.modeLegacy &&
            job.paymentStatus != PricingConstants.paymentNone) ...[
          const SizedBox(height: 12),
          Text(
            'Pago: ${JobDetailHelpers.paymentStatusLabel(job.paymentStatus)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (job.pricingMode == PricingConstants.modeOpenQuote) ...[
          const SizedBox(height: 12),
          OpenQuoteStatusBanner(
            jobStatus: job.status,
            isClient: !isWorker && isClientOwner,
            workerName: invitedWorkerName,
            proposalsCount: quoteProposals
                .where((p) => p.estado == PricingConstants.quoteSubmitted)
                .length,
          ),
        ],
        if (job.status == PricingConstants.jobAwaitingPayment &&
            !isWorker &&
            isClientOwner) ...[
          const SizedBox(height: 16),
          if (JobDetailHelpers.quoteFromJob(job) != null)
            PricingQuoteCard(quote: JobDetailHelpers.quoteFromJob(job)!),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onPayEscrow,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Pagar y confirmar reserva'),
          ),
        ],
        if (job.status == PricingConstants.jobAwaitingPayment && isWorker) ...[
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'El cliente debe completar el pago en garantía para confirmar el trabajo.',
              ),
            ),
          ),
        ],
        if (job.status == PricingConstants.jobAwaitingClientApproval &&
            !isWorker &&
            isClientOwner) ...[
          const SizedBox(height: 16),
          JobDetailClientApprovalCard(
            jobId: jobId,
            quote: JobDetailHelpers.quoteFromJob(job),
            onApprove: onApproveCompletion,
            onReject: onRejectCompletion,
          ),
        ],
        if (job.status == PricingConstants.jobAwaitingClientApproval &&
            isWorker &&
            isAssignedWorker) ...[
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Evidencia enviada. Esperando que el cliente apruebe la finalización para liberar el pago.',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
