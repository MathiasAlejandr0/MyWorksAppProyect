import 'package:flutter/material.dart';
import 'package:myworksapp/core/services/testing_feedback_store.dart';
import 'package:myworksapp/core/theme/app_colors.dart';

/// Formulario corto para quienes prueban la app antes del informe.
class TestingFeedbackSheet extends StatefulWidget {
  const TestingFeedbackSheet({super.key, required this.onSubmit});

  final Future<void> Function(TestingFeedbackDraft draft) onSubmit;

  static Future<void> show(
    BuildContext context, {
    Future<void> Function(TestingFeedbackDraft draft)? onSubmit,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => TestingFeedbackSheet(
        onSubmit: onSubmit ?? TestingFeedbackStore.save,
      ),
    );
    if (sent == true) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Gracias. Guardamos tu feedback de la prueba.'),
          ),
        );
    }
  }

  @override
  State<TestingFeedbackSheet> createState() => _TestingFeedbackSheetState();
}

class _TestingFeedbackSheetState extends State<TestingFeedbackSheet> {
  final _workedController = TextEditingController();
  final _improveController = TextEditingController();
  int _score = 0;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _workedController.dispose();
    _improveController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final draft = TestingFeedbackDraft(
      score: _score,
      worked: _workedController.text,
      improve: _improveController.text,
    );
    if (!draft.isValid) {
      setState(() {
        _error = 'Elige una nota y cuenta qué mejorar (mínimo 8 caracteres).';
      });
      return;
    }
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSubmit(draft);
      if (!mounted) return;
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo guardar el feedback. Intenta de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Feedback de la prueba'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cuéntanos qué tan fácil fue pedir un trabajo. Esto no se publica en el perfil.',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    tooltip: '$star de 5',
                    onPressed: _sending ? null : () => setState(() => _score = star),
                    icon: Icon(
                      star <= _score ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.brandOrange,
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _workedController,
              enabled: !_sending,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Qué te resultó claro',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _improveController,
              enabled: !_sending,
              decoration: const InputDecoration(
                labelText: 'Qué mejorarías',
              ),
              maxLines: 3,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'Enviando…' : 'Enviar'),
        ),
      ],
    );
  }
}
