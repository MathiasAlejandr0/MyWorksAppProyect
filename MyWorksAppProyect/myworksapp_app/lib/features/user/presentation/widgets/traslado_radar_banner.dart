import 'package:flutter/material.dart';

import '../../../../core/domain/transport_surcharge.dart';
import '../../../../core/theme/app_colors.dart';

class TrasladoRadarBanner extends StatelessWidget {
  const TrasladoRadarBanner({super.key, required this.quote});

  final TransportSurcharge quote;

  @override
  Widget build(BuildContext context) {
    final radius = quote.radiusKm.round();
    late final String text;
    late final Color color;
    if (quote.insideRadar == true) {
      text = 'El trabajo queda dentro de $radius km: sin extra de traslado.';
      color = AppColors.success;
    } else if (quote.insideRadar == false) {
      final km = quote.distanceKm?.toStringAsFixed(1) ?? '?';
      text =
          'Queda a $km km, fuera del área cercana. El traslado se confirma al pagar.';
      color = AppColors.brandOrange;
    } else {
      text =
          'Hasta $radius km cubre sin extra de traslado. Confirma tu ubicación para calcularlo.';
      color = AppColors.grayMedium;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.radar_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
