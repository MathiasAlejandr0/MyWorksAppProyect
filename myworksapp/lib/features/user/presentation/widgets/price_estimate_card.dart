import 'package:flutter/material.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/database/models/service_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget para mostrar precio estimado con disclaimer legal
/// 
/// Muestra precio calculado según pricingModel y valores ingresados.
/// Incluye disclaimer legal obligatorio sobre intermediación.
class PriceEstimateCard extends StatelessWidget {
  final ServiceModel service;
  final Map<String, dynamic>? serviceMetadata;
  final double? estimatedHours;
  final int? itemCount;

  const PriceEstimateCard({
    super.key,
    required this.service,
    this.serviceMetadata,
    this.estimatedHours,
    this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PriceEstimate>(
      future: _calculatePrice(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final estimate = snapshot.data!;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primaryLight.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: AppColors.primaryLight,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Precio Estimado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.grayDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimado',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grayMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estimate.getFormattedPrice(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    if (estimate.minimumPrice != estimate.estimatedPrice)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Mínimo',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grayMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            estimate.getFormattedMinimum(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grayDark,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (estimate.message != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            estimate.message!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grayDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Precio estimado sugerido. El valor final se acuerda directamente con el trabajador. MyWorksApp es solo intermediario.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grayDark,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<PriceEstimate> _calculatePrice() async {
    // Calcular horas estimadas según metadata si es necesario
    double? hours = estimatedHours;
    
    if (hours == null && serviceMetadata != null) {
      // Intentar calcular horas desde metadata según el servicio
      switch (service.pricingModel) {
        case 'hourly':
          // Para servicios por hora, intentar estimar desde metadata
          // Ejemplo: limpieza según tamaño
          if (serviceMetadata!.containsKey('size')) {
            final size = serviceMetadata!['size'] as String? ?? '';
            if (size.contains('Pequeño') || size.contains('Departamento')) {
              hours = 2.0;
            } else if (size.contains('Mediano') || size.contains('Casa pequeña')) {
              hours = 3.0;
            } else if (size.contains('Grande') || size.contains('Casa grande')) {
              hours = 4.0;
            } else {
              hours = 2.5; // Default
            }
          }
          break;
        case 'per_item':
          // Para servicios por ítem, usar itemCount
          if (itemCount != null && itemCount! > 0) {
            // Estimación: 1 hora por ítem
            hours = itemCount!.toDouble();
          }
          break;
        default:
          hours = null;
      }
    }

    return await PricingService.instance.getPriceEstimate(
      serviceId: service.id,
      estimatedHours: hours,
    );
  }
}

