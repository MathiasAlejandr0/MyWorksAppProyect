import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Acción elegida tras confirmar el envío de la solicitud.
enum ServiceRequestSubmittedAction {
  viewJob,
  goHome,
}

/// Confirmación tras enviar solicitud al profesional elegido.
class ServiceRequestSubmittedDialog extends StatelessWidget {
  const ServiceRequestSubmittedDialog({
    super.key,
    required this.workerName,
    required this.jobLabel,
  });

  final String workerName;
  final String jobLabel;

  static Future<ServiceRequestSubmittedAction> show(
    BuildContext context, {
    required String workerName,
    required String jobLabel,
  }) async {
    final result = await showDialog<ServiceRequestSubmittedAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ServiceRequestSubmittedDialog(
        workerName: workerName,
        jobLabel: jobLabel,
      ),
    );
    return result ?? ServiceRequestSubmittedAction.viewJob;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.send_rounded, color: AppColors.brandOrange, size: 40),
      title: const Text('Solicitud enviada'),
      content: Text(
        'Enviamos tu pedido de $jobLabel a $workerName. '
        'Revisará si puede realizar el trabajo y te avisaremos cuando responda.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            ServiceRequestSubmittedAction.goHome,
          ),
          child: const Text('Volver al inicio'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            ServiceRequestSubmittedAction.viewJob,
          ),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brandOrange),
          child: const Text('Ver solicitud'),
        ),
      ],
    );
  }
}
