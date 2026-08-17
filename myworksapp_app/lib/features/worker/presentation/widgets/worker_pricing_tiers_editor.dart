import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/domain/worker_service_options_catalog.dart';
import '../../../../core/theme/app_colors.dart';

/// Editor de tarifas por tipo de trabajo del profesional.
class WorkerPricingTiersEditor extends StatefulWidget {
  const WorkerPricingTiersEditor({
    super.key,
    required this.category,
    required this.initialTiers,
    required this.onChanged,
    this.enabled = true,
  });

  final String? category;
  final Map<String, int> initialTiers;
  final ValueChanged<Map<String, int>> onChanged;
  final bool enabled;

  @override
  State<WorkerPricingTiersEditor> createState() => _WorkerPricingTiersEditorState();
}

class _WorkerPricingTiersEditorState extends State<WorkerPricingTiersEditor> {
  late Map<String, int> _tiers;
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _tiers = Map<String, int>.from(widget.initialTiers);
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant WorkerPricingTiersEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.initialTiers != widget.initialTiers) {
      _tiers = Map<String, int>.from(widget.initialTiers);
      _syncControllers();
    }
  }

  void _syncControllers() {
    final options =
        WorkerServiceOptionsCatalog.pricingOptionsFor(widget.category);
    for (final option in options) {
      final value = WorkerServiceOptionsCatalog.priceFor(
        workerTiers: _tiers,
        option: option,
      );
      final controller = _controllers.putIfAbsent(
        option.id,
        () => TextEditingController(text: value.toString()),
      );
      if (controller.text != value.toString()) {
        controller.text = value.toString();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(Map<String, int>.from(_tiers));

  @override
  Widget build(BuildContext context) {
    final options =
        WorkerServiceOptionsCatalog.pricingOptionsFor(widget.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tarifas por tipo de trabajo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Estos valores los verá el cliente al solicitar tu servicio.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grayMedium,
              ),
        ),
        const SizedBox(height: 12),
        ...options.map((option) {
          final controller = _controllers.putIfAbsent(
            option.id,
            () => TextEditingController(
              text: WorkerServiceOptionsCatalog.priceFor(
                workerTiers: _tiers,
                option: option,
              ).toString(),
            ),
          );
          final suffix = option.unit == WorkerPriceUnit.perSqm ? 'CLP/m²' : 'CLP';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: controller,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: option.title,
                helperText: option.subtitle,
                suffixText: suffix,
                isDense: true,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed == null || parsed <= 0) return;
                setState(() => _tiers[option.id] = parsed);
                _emit();
              },
            ),
          );
        }),
      ],
    );
  }
}
