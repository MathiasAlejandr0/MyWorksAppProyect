import 'package:flutter/material.dart';

import '../../../../core/database/repositories/client_rating_repository.dart';
import '../../../../core/theme/app_colors.dart';

/// El especialista califica al cliente después de un trabajo completado.
class RateClientButton extends StatelessWidget {
  const RateClientButton({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.person_outline),
      label: const Text('Calificar al cliente'),
    );
  }

  Future<void> _open(BuildContext context) async {
    var score = 0;
    final comment = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Calificar al cliente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Esta nota queda en el perfil del cliente. No mueve el pago.',
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    onPressed: () => setLocal(() => score = value),
                    icon: Icon(
                      value <= score ? Icons.star : Icons.star_border,
                      color: AppColors.warning,
                    ),
                  );
                }),
              ),
              TextField(
                controller: comment,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: score == 0 ? null : () => Navigator.pop(ctx, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    final text = comment.text.trim();
    comment.dispose();
    if (saved != true || !context.mounted) return;

    try {
      await ClientRatingRepository().rateClient(
        jobId: jobId,
        score: score,
        comment: text.isEmpty ? null : text,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota del cliente guardada')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo calificar: $e')),
      );
    }
  }
}
