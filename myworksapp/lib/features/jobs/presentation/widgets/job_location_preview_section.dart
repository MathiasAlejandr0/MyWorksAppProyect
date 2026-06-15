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
    this.showApproximateHint = false,
  });

  final String address;
  final double latitude;
  final double longitude;
  final bool isLoadingAddress;
  final bool showApproximateHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              showApproximateHint ? Icons.location_searching : Icons.location_on,
              size: 20,
              color: showApproximateHint ? AppColors.warning : AppColors.brandOrange,
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: showApproximateHint
                                    ? FontStyle.italic
                                    : null,
                              ),
                        ),
                  if (showApproximateHint) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ubicación aproximada hasta que el trabajador acepte.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (!showApproximateHint) ...[
          const SizedBox(height: 10),
          JobLocationMap(
            latitude: latitude,
            longitude: longitude,
            height: 96,
          ),
        ],
      ],
    );
  }
}
