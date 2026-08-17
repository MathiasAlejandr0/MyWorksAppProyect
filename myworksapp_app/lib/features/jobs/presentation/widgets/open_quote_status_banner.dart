import 'package:flutter/material.dart';

import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Banner de estado para cotización abierta (cliente o trabajador).
class OpenQuoteStatusBanner extends StatelessWidget {
  const OpenQuoteStatusBanner({
    super.key,
    required this.jobStatus,
    required this.isClient,
    this.workerName,
    this.proposalsCount = 0,
  });

  final String jobStatus;
  final bool isClient;
  final String? workerName;
  final int proposalsCount;

  @override
  Widget build(BuildContext context) {
    if (jobStatus == PricingConstants.jobAwaitingQuotes) {
      return _box(
        context,
        color: AppColors.brandTeal.withValues(alpha: 0.08),
        border: AppColors.brandTeal,
        icon: Icons.hourglass_top_rounded,
        title: isClient ? 'Esperando respuesta del profesional' : 'Cliente espera tu cotización',
        body: isClient ? _clientWaitingText() : _workerWaitingText(),
      );
    }

    if (jobStatus == PricingConstants.jobAwaitingPayment && isClient) {
      return _box(
        context,
        color: AppColors.brandOrangeSoft,
        border: AppColors.brandOrange,
        icon: Icons.payment_outlined,
        title: 'Precio aceptado — falta el pago',
        body:
            'Aceptaste la propuesta del profesional. Completa el pago en garantía (demo) para confirmar el trabajo.',
      );
    }

    return const SizedBox.shrink();
  }

  String _clientWaitingText() {
    final name = workerName ?? 'El profesional';
    if (proposalsCount > 0) {
      return '$name te envió su propuesta. Revisa materiales, mano de obra y total; si te convence, pulsa «Aceptar cotización y continuar al pago».';
    }
    return '$name está evaluando tu solicitud. Cuando envíe su propuesta podrás revisar el desglose y decidir si aceptas el precio.';
  }

  String _workerWaitingText() {
    return 'Este cliente te eligió desde tu perfil. Prepara tu propuesta con materiales, mano de obra, horas estimadas y alcance.';
  }

  Widget _box(
    BuildContext context, {
    required Color color,
    required Color border,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: border,
                      ),
                ),
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
