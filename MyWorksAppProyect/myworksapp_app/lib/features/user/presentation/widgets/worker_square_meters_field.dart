import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/models/service_model.dart';
import '../../../../core/domain/worker_service_options_catalog.dart';
import '../../../../core/theme/app_colors.dart';

/// Campo para indicar m² cuando el cliente elige «Proyecto grande».
class WorkerSquareMetersField extends StatelessWidget {
  const WorkerSquareMetersField({
    super.key,
    required this.controller,
    required this.unitRateClp,
    required this.onChanged,
    this.serviceCategory,
    this.squareMeters,
    this.totalClp,
  });

  final TextEditingController controller;
  final int unitRateClp;
  final VoidCallback onChanged;
  final String? serviceCategory;
  final int? squareMeters;
  final int? totalClp;

  @override
  Widget build(BuildContext context) {
    final formattedRate = WorkerServiceOptionDef(
      id: '_',
      title: '',
      subtitle: '',
      icon: Icons.square_foot_outlined,
      defaultPriceClp: unitRateClp,
      unit: WorkerPriceUnit.perSqm,
    ).priceLabel(unitRateClp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandOrange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.square_foot_outlined, color: AppColors.brandOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Superficie del proyecto',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _hintForCategory(serviceCategory, formattedRate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grayMedium,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: serviceCategory == ServiceCategories.electrical
                  ? 'Metros cuadrados del proyecto eléctrico'
                  : 'Metros cuadrados a construir',
              hintText: 'Ej: 45',
              suffixText: 'm²',
              isDense: true,
            ),
            validator: (value) {
              final parsed = int.tryParse(value?.trim() ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Ingresa los m² del proyecto';
              }
              if (parsed > 5000) {
                return 'Consulta proyectos mayores a 5.000 m² con el profesional';
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          if (squareMeters != null && totalClp != null) ...[
            const SizedBox(height: 10),
            Text(
              'Total estimado: ${WorkerServiceOptionDef(id: '_', title: '', subtitle: '', icon: Icons.attach_money, defaultPriceClp: totalClp!).priceLabel(totalClp!)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.brandOrange,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  static String _hintForCategory(String? category, String formattedRate) {
    switch (category) {
      case ServiceCategories.electrical:
        return 'Tarifa del electricista: $formattedRate. Indica los m² del proyecto para calcular el total.';
      case ServiceCategories.construction:
        return 'Tarifa del maestro: $formattedRate. Indica cuántos m² quieres construir o remodelar.';
      default:
        return 'Tarifa del profesional: $formattedRate. Indica los metros cuadrados para calcular el total.';
    }
  }
}
