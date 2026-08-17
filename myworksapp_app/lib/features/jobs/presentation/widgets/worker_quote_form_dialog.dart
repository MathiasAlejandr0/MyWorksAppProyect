import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulario del trabajador: materiales, mano de obra, tiempo y alcance.
class WorkerQuoteFormResult {
  final int montoTotalClp;
  final String descripcion;
  final int materialesClp;
  final int manoObraClp;
  final int horasEstimadas;

  const WorkerQuoteFormResult({
    required this.montoTotalClp,
    required this.descripcion,
    required this.materialesClp,
    required this.manoObraClp,
    required this.horasEstimadas,
  });
}

class WorkerQuoteFormDialog extends StatefulWidget {
  const WorkerQuoteFormDialog({super.key});

  static Future<WorkerQuoteFormResult?> show(BuildContext context) {
    return showDialog<WorkerQuoteFormResult>(
      context: context,
      builder: (ctx) => const WorkerQuoteFormDialog(),
    );
  }

  @override
  State<WorkerQuoteFormDialog> createState() => _WorkerQuoteFormDialogState();
}

class _WorkerQuoteFormDialogState extends State<WorkerQuoteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _materialesCtrl = TextEditingController();
  final _manoObraCtrl = TextEditingController();
  final _horasCtrl = TextEditingController(text: '2');
  final _alcanceCtrl = TextEditingController();

  @override
  void dispose() {
    _materialesCtrl.dispose();
    _manoObraCtrl.dispose();
    _horasCtrl.dispose();
    _alcanceCtrl.dispose();
    super.dispose();
  }

  int get _total {
    final m = int.tryParse(_materialesCtrl.text.trim()) ?? 0;
    final l = int.tryParse(_manoObraCtrl.text.trim()) ?? 0;
    return m + l;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enviar cotización al cliente'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Evalúa materiales, mano de obra y tiempo. El cliente revisará tu propuesta antes de pagar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _materialesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Materiales (CLP)',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa un monto (0 si no aplica)';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _manoObraCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mano de obra (CLP)',
                  prefixIcon: Icon(Icons.engineering_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa un monto';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _horasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Horas estimadas',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _alcanceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alcance y detalle del trabajo',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().length < 15) {
                    return 'Describe el trabajo (mín. 15 caracteres)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Total propuesto: \$${_total.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (m) => '${m[1]}.',
                    )}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final total = _total;
            if (total < 5000) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El total mínimo es \$5.000')),
              );
              return;
            }
            Navigator.pop(
              context,
              WorkerQuoteFormResult(
                montoTotalClp: total,
                descripcion: _alcanceCtrl.text.trim(),
                materialesClp: int.parse(_materialesCtrl.text.trim()),
                manoObraClp: int.parse(_manoObraCtrl.text.trim()),
                horasEstimadas: int.tryParse(_horasCtrl.text.trim()) ?? 1,
              ),
            );
          },
          child: const Text('Enviar propuesta'),
        ),
      ],
    );
  }
}
