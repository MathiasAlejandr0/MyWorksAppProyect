import 'package:flutter/material.dart';

import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';

typedef OpenDisputeCallback = Future<void> Function(
  String reason,
  String? description,
);

typedef AddDisputeCommentCallback = Future<void> Function(String comment);
typedef ProposeAgreementCallback = Future<void> Function(String type);
typedef RespondAgreementCallback = Future<void> Function(bool accept);

class DisputeSection extends StatelessWidget {
  const DisputeSection({
    super.key,
    required this.dispute,
    required this.canOpenDispute,
    required this.isParticipant,
    this.onOpenDispute,
    this.onAddComment,
    this.onProposeAgreement,
    this.onRespondAgreement,
    this.pendingAgreementType,
    this.pendingAgreementId,
  });

  final DisputeModel? dispute;
  final bool canOpenDispute;
  final bool isParticipant;
  final OpenDisputeCallback? onOpenDispute;
  final AddDisputeCommentCallback? onAddComment;
  final ProposeAgreementCallback? onProposeAgreement;
  final RespondAgreementCallback? onRespondAgreement;
  final String? pendingAgreementType;
  final String? pendingAgreementId;

  @override
  Widget build(BuildContext context) {
    if (!isParticipant) return const SizedBox.shrink();

    if (dispute != null) {
      return _DisputeStatusCard(
        dispute: dispute!,
        onAddComment: onAddComment,
        onProposeAgreement: onProposeAgreement,
        onRespondAgreement: onRespondAgreement,
        pendingAgreementType: pendingAgreementType,
        pendingAgreementId: pendingAgreementId,
      );
    }

    if (!canOpenDispute || onOpenDispute == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppColors.brandOrangeSoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel, color: AppColors.brandOrange),
                const SizedBox(width: 8),
                Text(
                  '¿Problema con el trabajo?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Si los dos están de acuerdo, el sistema cierra el caso. Si abres una disputa, el pago queda retenido: los casos simples se cierran solos al vencer el plazo y el resto lo ve una persona.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (pendingAgreementType != null) ...[
              const SizedBox(height: 8),
              Text('Acuerdo pendiente: $pendingAgreementType'),
              if (onRespondAgreement != null && pendingAgreementId != null)
                Row(
                  children: [
                    TextButton(
                      onPressed: () => onRespondAgreement!(true),
                      child: const Text('Confirmar'),
                    ),
                    TextButton(
                      onPressed: () => onRespondAgreement!(false),
                      child: const Text('Rechazar'),
                    ),
                  ],
                ),
            ],
            if (onProposeAgreement != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => onProposeAgreement!('aceptar'),
                    child: const Text('Aceptar entrega'),
                  ),
                  TextButton(
                    onPressed: () => onProposeAgreement!('rehacer'),
                    child: const Text('Rehacer'),
                  ),
                  TextButton(
                    onPressed: () => onProposeAgreement!('anular'),
                    child: const Text('Anular'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openDisputeFlow(context),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Abrir disputa'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDisputeFlow(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DisputeReasonDialog(),
    );
    if (reason == null || !context.mounted) return;

    final descriptionCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle de la disputa'),
        content: TextField(
          controller: descriptionCtrl,
          decoration: const InputDecoration(
            labelText: 'Describe el problema (opcional)',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar disputa'),
          ),
        ],
      ),
    );

    final description = descriptionCtrl.text.trim();
    descriptionCtrl.dispose();

    if (confirm != true || !context.mounted || onOpenDispute == null) return;
    await onOpenDispute!(
      reason,
      description.isEmpty ? null : description,
    );
  }
}

class _DisputeStatusCard extends StatefulWidget {
  const _DisputeStatusCard({
    required this.dispute,
    this.onAddComment,
    this.onProposeAgreement,
    this.onRespondAgreement,
    this.pendingAgreementType,
    this.pendingAgreementId,
  });

  final DisputeModel dispute;
  final AddDisputeCommentCallback? onAddComment;
  final ProposeAgreementCallback? onProposeAgreement;
  final RespondAgreementCallback? onRespondAgreement;
  final String? pendingAgreementType;
  final String? pendingAgreementId;

  @override
  State<_DisputeStatusCard> createState() => _DisputeStatusCardState();
}

class _DisputeStatusCardState extends State<_DisputeStatusCard> {
  final _commentCtrl = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  DisputeModel get dispute => widget.dispute;

  String _reasonLabel(String reason) {
    switch (reason) {
      case AppConstants.disputeReasonQuality:
        return 'Calidad del trabajo';
      case AppConstants.disputeReasonPayment:
        return 'Pago';
      case AppConstants.disputeReasonBehavior:
        return 'Conducta';
      default:
        return 'Otro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = dispute.status == AppConstants.disputeStatusOpen ||
        dispute.status == AppConstants.disputeStatusUnderReview ||
        dispute.status == AppConstants.disputeStatusNeedsHuman ||
        dispute.status == AppConstants.disputeStatusRefundPending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOpen ? Icons.gavel : Icons.check_circle_outline,
                  color: isOpen ? AppColors.brandOrange : AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  dispute.status == AppConstants.disputeStatusNeedsHuman
                      ? 'Una persona va a revisar este caso'
                      : dispute.status == AppConstants.disputeStatusRefundPending
                          ? 'La devolución a la tarjeta está en curso'
                          : isOpen
                              ? 'Disputa abierta'
                              : 'Disputa resuelta',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Motivo: ${_reasonLabel(dispute.reason)}'),
            if (dispute.rule != null) Text('Regla: ${dispute.rule}'),
            if (widget.pendingAgreementType != null)
              Text('Acuerdo pendiente: ${widget.pendingAgreementType}'),
            if (widget.onProposeAgreement != null)
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => widget.onProposeAgreement!('aceptar'),
                    child: const Text('Aceptar entrega'),
                  ),
                  TextButton(
                    onPressed: () => widget.onProposeAgreement!('rehacer'),
                    child: const Text('Rehacer'),
                  ),
                  TextButton(
                    onPressed: () => widget.onProposeAgreement!('anular'),
                    child: const Text('Anular'),
                  ),
                ],
              ),
            if (widget.onRespondAgreement != null && widget.pendingAgreementId != null)
              Row(
                children: [
                  TextButton(
                    onPressed: () => widget.onRespondAgreement!(true),
                    child: const Text('Confirmar acuerdo'),
                  ),
                  TextButton(
                    onPressed: () => widget.onRespondAgreement!(false),
                    child: const Text('Rechazar'),
                  ),
                ],
              ),
            if (dispute.description != null && dispute.description!.isNotEmpty)
              Text(dispute.description!),
            if (dispute.resolution != null) ...[
              const SizedBox(height: 8),
              Text(
                'Resolución: ${dispute.resolution}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (isOpen && widget.onAddComment != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Agregar comentario',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _sending
                    ? null
                    : () async {
                        final text = _commentCtrl.text.trim();
                        if (text.isEmpty) return;
                        setState(() => _sending = true);
                        await widget.onAddComment!(text);
                        if (!mounted) return;
                        _commentCtrl.clear();
                        setState(() => _sending = false);
                      },
                child: Text(_sending ? 'Enviando…' : 'Agregar comentario'),
              ),
            ],
            if (isOpen)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Calificación y pago retenidos hasta resolución.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grayMedium,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DisputeReasonDialog extends StatelessWidget {
  const _DisputeReasonDialog();

  static const _reasons = [
    (AppConstants.disputeReasonQuality, 'Calidad del trabajo'),
    (AppConstants.disputeReasonPayment, 'Problema de pago'),
    (AppConstants.disputeReasonBehavior, 'Conducta'),
    (AppConstants.disputeReasonOther, 'Otro'),
  ];

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Motivo de la disputa'),
      children: _reasons
          .map(
            (r) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, r.$1),
              child: Text(r.$2),
            ),
          )
          .toList(),
    );
  }
}
