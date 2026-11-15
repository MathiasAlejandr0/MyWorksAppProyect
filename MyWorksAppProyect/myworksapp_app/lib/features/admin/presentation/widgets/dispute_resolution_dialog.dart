import 'package:flutter/material.dart';

/// Decisión de atención al cliente al cerrar una disputa.
class DisputeResolutionRequest {
  const DisputeResolutionRequest({
    required this.decision,
    required this.resolution,
  });

  /// `liberar` o `reembolsar`.
  final String decision;
  final String resolution;
}

Future<DisputeResolutionRequest?> showDisputeResolutionDialog(
  BuildContext context,
) {
  final resolutionCtrl = TextEditingController();
  return showDialog<DisputeResolutionRequest>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Resolver disputa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'El pago sigue retenido hasta esta decisión. Elige si el dinero va al profesional o vuelve a la tarjeta del cliente.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: resolutionCtrl,
            decoration: const InputDecoration(
              labelText: 'Qué se acordó',
              helperText: 'Mínimo 4 caracteres',
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final text = resolutionCtrl.text.trim();
            if (text.length < 4) return;
            Navigator.pop(
              ctx,
              DisputeResolutionRequest(decision: 'reembolsar', resolution: text),
            );
          },
          child: const Text('Devolver a la tarjeta'),
        ),
        FilledButton(
          onPressed: () {
            final text = resolutionCtrl.text.trim();
            if (text.length < 4) return;
            Navigator.pop(
              ctx,
              DisputeResolutionRequest(decision: 'liberar', resolution: text),
            );
          },
          child: const Text('Liberar al profesional'),
        ),
      ],
    ),
  ).whenComplete(resolutionCtrl.dispose);
}
