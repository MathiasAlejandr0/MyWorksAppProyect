import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// Radio donde la movilización queda en $0, y el cobro fijo fuera de esa zona.
class WorkerUrbanCoverageCard extends StatefulWidget {
  const WorkerUrbanCoverageCard({
    super.key,
    required this.urbanRadiusKm,
    required this.outsideFeeClp,
    required this.enabled,
    required this.onSave,
  });

  final double urbanRadiusKm;
  final int outsideFeeClp;
  final bool enabled;
  final Future<void> Function(double urbanRadiusKm, int outsideFeeClp) onSave;

  @override
  State<WorkerUrbanCoverageCard> createState() => _WorkerUrbanCoverageCardState();
}

class _WorkerUrbanCoverageCardState extends State<WorkerUrbanCoverageCard> {
  late final TextEditingController _km = TextEditingController(
    text: widget.urbanRadiusKm.toStringAsFixed(0),
  );
  late final TextEditingController _fee = TextEditingController(
    text: widget.outsideFeeClp.toString(),
  );
  bool _saving = false;
  String? _error;

  @override
  void didUpdateWidget(WorkerUrbanCoverageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _km.text = widget.urbanRadiusKm.toStringAsFixed(0);
      _fee.text = widget.outsideFeeClp.toString();
    }
  }

  @override
  void dispose() {
    _km.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final km = double.tryParse(_km.text.replaceAll(',', '.'));
    final fee = int.tryParse(_fee.text.replaceAll('.', '').trim());
    if (km == null || km < 1 || km > 40) {
      setState(() => _error = 'El radio urbano va de 1 a 40 km.');
      return;
    }
    if (fee == null || fee < 0 || fee > 200000) {
      setState(() => _error = 'La movilización fuera del radio va de 0 a 200.000.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(km, fee);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar el radio urbano.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Radio urbano sin recargo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Dentro de estos kilómetros desde tu base, la movilización es \$0. '
              'Fuera, el cliente ve este cobro fijo antes de reservar. '
              'En Puerto Montt, 5 km cubre el casco urbano.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _km,
              enabled: widget.enabled && !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Radio urbano (km)',
                prefixIcon: Icon(Icons.radar),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fee,
              enabled: widget.enabled && !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Movilización fuera del radio (CLP)',
                prefixIcon: Icon(Icons.payments_outlined),
                helperText: '0 si tampoco cobras fuera de la zona',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: widget.enabled && !_saving ? _save : null,
                child: Text(_saving ? 'Guardando…' : 'Guardar radio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
