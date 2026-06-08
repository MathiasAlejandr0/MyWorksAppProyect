import 'package:flutter/material.dart';



import '../../../../core/database/models/worker_model.dart';

import '../../../../core/domain/worker_service_options_catalog.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_worker_mapper.dart';



/// Selección de trabajo con tarifas publicadas por el profesional.

class WorkerServiceOptionPicker extends StatefulWidget {

  const WorkerServiceOptionPicker({

    super.key,

    required this.worker,

    required this.category,

    required this.onSelected,

    this.initialOptionId,

  });



  final WorkerModel worker;

  final String? category;

  final ValueChanged<WorkerServiceOptionDef> onSelected;

  final String? initialOptionId;



  @override

  State<WorkerServiceOptionPicker> createState() =>

      _WorkerServiceOptionPickerState();

}



class _WorkerServiceOptionPickerState extends State<WorkerServiceOptionPicker> {

  String? _selectedId;

  bool _showCustomServices = false;



  @override

  void initState() {

    super.initState();

    _selectedId = widget.initialOptionId;

  }



  List<WorkerServiceOptionDef> get _catalogOptions =>
      WorkerServiceOptionsCatalog.clientOptionsFor(widget.worker);



  List<WorkerServiceOptionDef> get _customOptions =>

      WorkerServiceOptionsCatalog.customOptionsFor(widget.worker);



  String? get _categoryLabel {
    final label = ServiceWorkerMapper.labelForCategory(widget.category);
    return label?.toLowerCase();
  }



  Widget _optionCard(WorkerServiceOptionDef option) {

    final price = WorkerServiceOptionsCatalog.priceForWorker(

      worker: widget.worker,

      option: option,

    );

    final selected = _selectedId == option.id;



    return Padding(

      padding: const EdgeInsets.only(bottom: 8),

      child: Material(

        color: selected ? AppColors.brandOrangeSoft : Colors.grey.shade50,

        borderRadius: BorderRadius.circular(12),

        child: InkWell(

          borderRadius: BorderRadius.circular(12),

          onTap: () {

            setState(() => _selectedId = option.id);

            widget.onSelected(option);

          },

          child: Container(

            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(12),

              border: Border.all(

                color: selected

                    ? AppColors.brandOrange

                    : AppColors.grayMedium.withValues(alpha: 0.2),

                width: selected ? 1.5 : 1,

              ),

            ),

            padding: const EdgeInsets.all(14),

            child: Row(

              children: [

                Icon(option.icon, color: AppColors.brandNavy),

                const SizedBox(width: 12),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        option.title,

                        style: Theme.of(context)

                            .textTheme

                            .titleSmall

                            ?.copyWith(fontWeight: FontWeight.w600),

                      ),

                      Text(

                        option.subtitle,

                        style: Theme.of(context)

                            .textTheme

                            .bodySmall

                            ?.copyWith(color: AppColors.grayMedium),

                      ),

                    ],

                  ),

                ),

                const SizedBox(width: 8),

                Container(

                  padding: const EdgeInsets.symmetric(

                    horizontal: 10,

                    vertical: 6,

                  ),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(8),

                    border: Border.all(

                      color: AppColors.brandOrange.withValues(alpha: 0.35),

                    ),

                  ),

                  child: Text(

                    option.priceLabel(price),

                    style: Theme.of(context).textTheme.labelMedium?.copyWith(

                          color: AppColors.brandOrange,

                          fontWeight: FontWeight.w800,

                        ),

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final label = _categoryLabel;

    final customOptions = _customOptions;



    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        Text(

          '¿Qué trabajo necesitas?',

          style: Theme.of(context).textTheme.titleMedium?.copyWith(

                fontWeight: FontWeight.w700,

              ),

        ),

        const SizedBox(height: 4),

        Text(

          label == null

              ? 'Elige una opción. Los valores los define ${widget.worker.profession}.'

              : 'Tarifas de ${widget.worker.profession} para trabajos de $label.',

          style: Theme.of(context).textTheme.bodySmall?.copyWith(

                color: AppColors.grayMedium,

              ),

        ),

        const SizedBox(height: 12),

        ..._catalogOptions.map(_optionCard),

        if (customOptions.isNotEmpty) ...[

          const SizedBox(height: 4),

          OutlinedButton.icon(

            onPressed: () => setState(() => _showCustomServices = !_showCustomServices),

            icon: Icon(_showCustomServices ? Icons.expand_less : Icons.expand_more),

            label: Text(_showCustomServices ? 'Ocultar más servicios' : 'Ver más'),

            style: OutlinedButton.styleFrom(

              foregroundColor: AppColors.brandNavy,

              side: BorderSide(color: AppColors.brandOrange.withValues(alpha: 0.5)),

            ),

          ),

          if (_showCustomServices) ...[

            const SizedBox(height: 8),

            Text(

              'Servicios adicionales de ${widget.worker.profession}',

              style: Theme.of(context).textTheme.labelLarge?.copyWith(

                    fontWeight: FontWeight.w600,

                    color: AppColors.grayMedium,

                  ),

            ),

            const SizedBox(height: 8),

            ...customOptions.map(_optionCard),

          ],

        ],

      ],

    );

  }

}


