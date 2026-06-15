import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/job_location_map.dart';

/// Resumen compacto de ubicación y agenda para el trabajador tras aceptar.
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
    final scheduleText = scheduledDate == null
        ? 'Fecha y hora: a coordinar con el cliente'
        : DateFormat('EEE d MMM · HH:mm', 'es_CL').format(scheduledDate!);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: AppColors.brandOrange.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubicación del trabajo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            JobLocationMap(
              latitude: latitude,
              longitude: longitude,
              height: 96,
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            if (isLoadingAddress)
              const Text('Obteniendo dirección...')
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_outlined, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  scheduledDate == null ? Icons.event_busy : Icons.event,
                  size: 18,
                  color: AppColors.brandOrange,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    scheduleText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontStyle: scheduledDate == null
                              ? FontStyle.italic
                              : null,
                          color: scheduledDate == null
                              ? AppColors.grayMedium
                              : null,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
