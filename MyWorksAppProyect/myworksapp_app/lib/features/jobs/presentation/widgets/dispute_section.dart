import 'package:flutter/material.dart';

import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../utils/job_detail_helpers.dart';

typedef OpenDisputeCallback = Future<void> Function(
  String reason,
  String? description,
);

typedef AddDisputeCommentCallback = Future<void> Function(String comment);
typedef AppealDisputeCallback = Future<void> Function(String motivo);
typedef ProposeAgreementCallback = Future<void> Function(String type);
typedef RespondAgreementCallback = Future<void> Function(bool accept);

class DisputeSection extends StatelessWidget {
  const DisputeSection({
    super.key,
    required this.dispute,
    required this.canOpenDispute,
    required this.isParticipant,
    this.canNegotiate = false,
    this.onOpenDispute,
    this.onAddComment,
    this.onAppeal,
    this.onProposeAgreement,
    this.onRespondAgreement,
    this.pendingAgreementType,
    this.pendingAgreementId,
  });

  final DisputeModel? dispute;
  final bool canOpenDispute;
  final bool isParticipant;

  /// Con la disputa cerrada o el trabajo terminado no se ofrecen acuerdos.
  final bool canNegotiate;
  final OpenDisputeCallback? onOpenDispute;
  final AddDisputeCommentCallback? onAddComment;
  final AppealDisputeCallback? onAppeal;
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
        onAppeal: onAppeal,
        onProposeAgreement: canNegotiate ? onProposeAgreement : null,
        onRespondAgreement: canNegotiate ? onRespondAgreement : null,
        pendingAgreementType: canNegotiate ? pendingAgreementType : null,
        pendingAgreementId: canNegotiate ? pendingAgreementId : null,
      );
    }

    if (!canOpenDispute || onOpenDispute == null) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);

    return _DisputeFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _DisputeIconBadge(icon: Icons.gavel),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿Problema con el trabajo?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Si los dos están de acuerdo, el sistema cierra el caso. Si abres una disputa, el pago queda retenido: los casos simples se cierran solos al vencer el plazo y el resto lo ve una persona.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: muted,
                  height: 1.4,
                  fontSize: 13,
                ),
          ),
            if (pendingAgreementType != null) ...[
              const SizedBox(height: 8),
              Text(
                'Acuerdo pendiente: '
                '${JobDetailHelpers.agreementTypeLabel(pendingAgreementType)}',
              ),
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
              const SizedBox(height: 16),
              _AgreementActions(onPropose: onProposeAgreement!),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openDisputeFlow(context),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Abrir disputa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: titleColor,
                side: const BorderSide(color: AppColors.brandOrange, width: 1.5),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
    );
  }

  Future<void> _openDisputeFlow(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DisputeReasonDialog(),
    );
    if (reason == null || !context.mounted) return;

    final description = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DisputeDetailDialog(),
    );

    if (description == null || !context.mounted || onOpenDispute == null) {
      return;
    }
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
    this.onAppeal,
    this.onProposeAgreement,
    this.onRespondAgreement,
    this.pendingAgreementType,
    this.pendingAgreementId,
  });

  final DisputeModel dispute;
  final AddDisputeCommentCallback? onAddComment;
  final AppealDisputeCallback? onAppeal;
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

    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final accent = isOpen ? AppColors.brandOrange : AppColors.success;

    return _DisputeFrame(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DisputeIconBadge(
                icon: isOpen ? Icons.gavel : Icons.check_circle_outline,
                color: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dispute.status == AppConstants.disputeStatusNeedsHuman
                      ? 'Una persona va a revisar este caso'
                      : dispute.status ==
                              AppConstants.disputeStatusRefundPending
                          ? 'La devolución a la tarjeta está en curso'
                          : isOpen
                              ? 'Disputa abierta'
                              : 'Disputa resuelta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Motivo: ${_reasonLabel(dispute.reason)}',
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
          ),
            if (dispute.rule != null) Text('Regla: ${dispute.rule}'),
            if (widget.pendingAgreementType != null)
              Text(
                'Acuerdo pendiente: '
                '${JobDetailHelpers.agreementTypeLabel(widget.pendingAgreementType)}',
              ),
            if (isOpen && widget.onProposeAgreement != null) ...[
              const SizedBox(height: 16),
              _AgreementActions(onPropose: widget.onProposeAgreement!),
            ],
            if (isOpen &&
                widget.onRespondAgreement != null &&
                widget.pendingAgreementId != null)
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
            if (!isOpen &&
                dispute.origin == 'sistema' &&
                widget.onAppeal != null) ...[
              const SizedBox(height: 12),
              Text(
                'Si el sistema cerró el caso, puedes pedir que una persona lo revise. Pedirlo no vuelve a mover el dinero.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final motivo = await showDialog<String>(
                    context: context,
                    builder: (ctx) => const _AppealDialog(),
                  );
                  if (motivo == null || motivo.trim().length < 10) return;
                  await widget.onAppeal!(motivo.trim());
                },
                child: const Text('Pedir revisión humana'),
              ),
            ],
            if (isOpen)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Calificación y pago retenidos hasta resolución.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                        height: 1.35,
                      ),
                ),
              ),
          ],
        ),
    );
  }
}

class _DisputeFrame extends StatelessWidget {
  const _DisputeFrame({
    required this.child,
    this.accent = AppColors.brandOrange,
  });

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDarkElevated : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.22)
              : AppColors.grayBorder,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: accent,
              child: const SizedBox(width: 4),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputeIconBadge extends StatelessWidget {
  const _DisputeIconBadge({
    required this.icon,
    this.color = AppColors.brandOrange,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? AppColors.surfaceDarkElevated : AppColors.surfaceLight;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: dark ? 0.28 : 0.14),
          base,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _AppealDialog extends StatefulWidget {
  const _AppealDialog();

  @override
  State<_AppealDialog> createState() => _AppealDialogState();
}

class _AppealDialogState extends State<_AppealDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pedir revisión humana'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Por qué pides la revisión',
          alignLabelWithHint: true,
        ),
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

class _DisputeDetailDialog extends StatefulWidget {
  const _DisputeDetailDialog();

  @override
  State<_DisputeDetailDialog> createState() => _DisputeDetailDialogState();
}

class _DisputeDetailDialogState extends State<_DisputeDetailDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalle de la disputa'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Describe el problema (opcional)',
          alignLabelWithHint: true,
        ),
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandOrange,
          ),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Enviar disputa'),
        ),
      ],
    );
  }
}

class _Choice {
  const _Choice(this.value, this.title, this.detail, this.icon);

  final String value;
  final String title;
  final String detail;
  final IconData icon;
}

class _DisputeReasonDialog extends StatefulWidget {
  const _DisputeReasonDialog();

  @override
  State<_DisputeReasonDialog> createState() => _DisputeReasonDialogState();
}

class _DisputeReasonDialogState extends State<_DisputeReasonDialog> {
  static const _reasons = [
    _Choice(
      AppConstants.disputeReasonQuality,
      'Calidad del trabajo',
      'El resultado no quedó como se acordó.',
      Icons.handyman_outlined,
    ),
    _Choice(
      AppConstants.disputeReasonPayment,
      'Problema de pago',
      'El cobro o la garantía no cuadran.',
      Icons.payments_outlined,
    ),
    _Choice(
      AppConstants.disputeReasonBehavior,
      'Conducta',
      'Hubo un trato inadecuado durante el trabajo.',
      Icons.person_outline,
    ),
    _Choice(
      AppConstants.disputeReasonOther,
      'Otro',
      'El caso no entra en las opciones de arriba.',
      Icons.more_horiz,
    ),
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);
    return Dialog(
      backgroundColor: AppColors.surfaceOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Motivo de la disputa',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige una opción. El pago sigue retenido hasta cerrar el caso.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 16),
              for (final reason in _reasons) ...[
                _SelectableOptionCard(
                  title: reason.title,
                  detail: reason.detail,
                  icon: reason.icon,
                  selected: _selected == reason.value,
                  onTap: () => setState(() => _selected = reason.value),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              FilledButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.pop(context, _selected),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Continuar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementActions extends StatelessWidget {
  const _AgreementActions({required this.onPropose});

  final ProposeAgreementCallback onPropose;

  static const _actions = [
    _Choice(
      'aceptar',
      'Aceptar entrega',
      'El trabajo queda conforme y se puede liberar el pago.',
      Icons.check_circle_outline,
    ),
    _Choice(
      'rehacer',
      'Rehacer',
      'El profesional vuelve a hacer la parte que no quedó bien.',
      Icons.replay,
    ),
    _Choice(
      'anular',
      'Anular',
      'Se deja sin efecto el trabajo y se revisa la devolución.',
      Icons.cancel_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Proponer un acuerdo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _SelectableOptionCard(
            title: _actions[i].title,
            detail: _actions[i].detail,
            icon: _actions[i].icon,
            showRadio: false,
            onTap: () => onPropose(_actions[i].value),
          ),
        ],
      ],
    );
  }
}

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.showRadio = true,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool showRadio;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF0E1624) : AppColors.grayLight;
    final border = selected
        ? AppColors.brandOrange
        : (dark ? Colors.white.withValues(alpha: 0.28) : AppColors.grayBorder);
    final fill = selected
        ? Color.alphaBlend(
            AppColors.brandOrange.withValues(alpha: dark ? 0.24 : 0.14),
            base,
          )
        : base;
    final titleColor = AppColors.onCanvas(Theme.of(context).brightness);
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brandOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                showRadio
                    ? (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked)
                    : Icons.chevron_right,
                color: selected || !showRadio
                    ? AppColors.brandOrange
                    : muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
