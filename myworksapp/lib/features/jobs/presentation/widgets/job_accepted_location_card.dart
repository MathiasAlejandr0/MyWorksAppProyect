import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/job_location_map.dart';

/// Resumen de ubicación y agenda para el trabajador tras aceptar el trabajo.
class JobAcceptedLocationCard extends StatelessWidget {
  const JobAcceptedLocationCard({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.scheduledDate,
    this.isLoadingAddress = false,
  });

  final String address;
  final double latitude;
  final double longitude;
  final DateTime? scheduledDate;
  final bool isLoadingAddress;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE d MMMM yyyy', 'es_CL');
    final timeFmt = DateFormat('HH:mm');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.brandOrange.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place, color: AppColors.brandOrange),
                const SizedBox(width: 8),
                Text(
                  'Ubicación del trabajo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: JobLocationMap(
                latitude: latitude,
                longitude: longitude,
                square: true,
              ),
            ),
            const SizedBox(height: 12),
            if (isLoadingAddress)
              const Text('Obteniendo dirección...')
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            if (scheduledDate != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.event, color: AppColors.brandOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    dateFmt.format(scheduledDate!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.brandOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    timeFmt.format(scheduledDate!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Fecha y hora: a coordinar con el cliente',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
