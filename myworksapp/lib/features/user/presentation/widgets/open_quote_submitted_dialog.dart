import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Mensaje tras enviar solicitud de cotización al profesional elegido.
class OpenQuoteSubmittedDialog extends StatelessWidget {
  const OpenQuoteSubmittedDialog({
    super.key,
    required this.workerName,
  });

  final String workerName;

  static Future<void> show(
    BuildContext context, {
    required String workerName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OpenQuoteSubmittedDialog(workerName: workerName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.hourglass_top_rounded, color: AppColors.brandTeal, size: 40),
      title: const Text('Solicitud enviada'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enviamos tu solicitud a $workerName. Debe revisar tu pedido y responderte con una propuesta personalizada.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
            Text(
              'Su propuesta incluirá:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const _Bullet('Costo estimado de materiales'),
            const _Bullet('Mano de obra y tiempo de trabajo'),
            const _Bullet('Alcance detallado del servicio'),
            const SizedBox(height: 14),
            _StepList(steps: [
              'Espera la respuesta de $workerName',
              'Revisa la propuesta cuando llegue',
              'Si aceptas el precio, continúas al pago',
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandOrangeSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'No debes pagar todavía. Te avisaremos en cuanto $workerName responda con su cotización.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ver mi solicitud'),
        ),
      ],
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximos pasos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...List.generate(steps.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
