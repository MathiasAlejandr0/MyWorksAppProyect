import 'package:flutter/material.dart';

import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/theme/app_colors.dart';

typedef OpenDisputeCallback = Future<void> Function(
  String reason,
  String? description,
);

class DisputeSection extends StatelessWidget {
  const DisputeSection({
    super.key,
    required this.dispute,
    required this.canOpenDispute,
    required this.isParticipant,
    this.onOpenDispute,
  });

  final DisputeModel? dispute;
  final bool canOpenDispute;
  final bool isParticipant;
  final OpenDisputeCallback? onOpenDispute;

  @override
  Widget build(BuildContext context) {
    if (!isParticipant) return const SizedBox.shrink();

    if (dispute != null) {
      return _DisputeStatusCard(dispute: dispute!);
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
              'Puedes abrir una disputa. Se congelará la calificación y el pago hasta resolverla.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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

class _DisputeStatusCard extends StatelessWidget {
  const _DisputeStatusCard({required this.dispute});

  final DisputeModel dispute;

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'quality':
        return 'Calidad del trabajo';
      case 'payment':
        return 'Pago';
      case 'behavior':
        return 'Conducta';
      default:
        return 'Otro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = dispute.status == 'open' || dispute.status == 'under_review';

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
                  isOpen ? 'Disputa abierta' : 'Disputa resuelta',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Motivo: ${_reasonLabel(dispute.reason)}'),
            if (dispute.description != null && dispute.description!.isNotEmpty)
              Text(dispute.description!),
            if (dispute.resolution != null) ...[
              const SizedBox(height: 8),
              Text(
                'Resolución: ${dispute.resolution}',
                style: const TextStyle(fontWeight: FontWeight.w600),
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
    ('quality', 'Calidad del trabajo'),
    ('payment', 'Problema de pago'),
    ('behavior', 'Conducta'),
    ('other', 'Otro'),
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
