import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/job_location_map.dart';

/// Bloque compacto: dirección + mini mapa (sin repetir títulos ni secciones).
class JobLocationPreviewSection extends StatelessWidget {
  const JobLocationPreviewSection({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isLoadingAddress = false,
  });

  final String address;
  final double latitude;
  final double longitude;
  final bool isLoadingAddress;

  @override
  Widget build(BuildContext context) {
    final hasMap = JobLocationMap.hasUsablePoint(latitude, longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación del trabajo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (hasMap) ...[
          JobLocationMap(
            latitude: latitude,
            longitude: longitude,
            height: 160,
          ),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasMap ? Icons.location_on : Icons.location_searching,
              size: 20,
              color: hasMap ? AppColors.brandOrange : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isLoadingAddress
                      ? const Text('Obteniendo ubicación...')
                      : Text(
                          address,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                  if (!hasMap) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Todavía no hay un punto en el mapa para este trabajo.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grayMedium,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
