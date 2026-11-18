import 'package:flutter/material.dart';
import 'package:myworksapp/core/services/testing_feedback_store.dart';
import 'package:myworksapp/core/theme/app_colors.dart';

/// Encuesta de testing (UAT) para quienes prueban la app. Es la misma de la
/// web: SUS de 10 afirmaciones, satisfacción, tarea y comentarios.
class TestingFeedbackSheet extends StatefulWidget {
  const TestingFeedbackSheet({
    super.key,
    required this.onSubmit,
    this.role = 'cliente',
  });

  final Future<void> Function(TestingFeedbackDraft draft) onSubmit;
  final String role;

  static Future<void> show(
    BuildContext context, {
    Future<void> Function(TestingFeedbackDraft draft)? onSubmit,
    String role = 'cliente',
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => TestingFeedbackSheet(
        onSubmit: onSubmit ?? TestingFeedbackStore.save,
        role: role,
      ),
    );
    if (sent == true) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Gracias. Guardamos tu encuesta de la prueba.'),
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
  final List<int> _sus = List<int>.filled(10, 0);
  int _score = 0;
  String _task = 'si';
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
      sus: List<int>.of(_sus),
      role: widget.role,
      taskCompleted: _task,
    );
    if (!draft.isValid) {
      setState(() {
        _error = _score < 1
            ? 'Elige tu satisfacción general (1 a 5 estrellas).'
            : 'Responde las 10 afirmaciones (llevas ${draft.susAnswered} de 10).';
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
        _error = 'No se pudo enviar la encuesta. Revisa tu conexión e intenta de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _scale(int index) {
    return Wrap(
      spacing: 4,
      children: [
        for (var value = 1; value <= 5; value++)
          ChoiceChip(
            label: Text('$value'),
            selected: _sus[index] == value,
            onSelected: _sending
                ? null
                : (_) => setState(() => _sus[index] = value),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;
    return AlertDialog(
      title: const Text('Encuesta de la prueba'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Toma unos 3 minutos y es anónima. No se publica en tu perfil.',
              ),
              const SizedBox(height: 12),
              const Text('¿Pudiste completar lo que querías hacer?'),
              Wrap(
                spacing: 6,
                children: [
                  for (final option in const [
                    ('si', 'Sí'),
                    ('parcial', 'En parte'),
                    ('no', 'No'),
                  ])
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: _task == option.$1,
                      onSelected: _sending
                          ? null
                          : (_) => setState(() => _task = option.$1),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Satisfacción general'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      tooltip: '$star de 5',
                      onPressed:
                          _sending ? null : () => setState(() => _score = star),
                      icon: Icon(
                        star <= _score
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.brandOrange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Qué tan de acuerdo estás: 1 = muy en desacuerdo, 5 = muy de acuerdo.',
                style: muted,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < TestingSurvey.susItems.length; i++) ...[
                Text('${i + 1}. ${TestingSurvey.susItems[i]}'),
                _scale(i),
                const SizedBox(height: 6),
              ],
              TextField(
                controller: _workedController,
                enabled: !_sending,
                maxLength: 1000,
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
                maxLength: 1000,
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
