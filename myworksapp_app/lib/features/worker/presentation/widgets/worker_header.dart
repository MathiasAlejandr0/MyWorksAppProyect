import 'package:flutter/material.dart';

import '../../../../core/database/models/worker_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_guided_tour.dart';

class WorkerHeader extends StatelessWidget {
  const WorkerHeader({
    super.key,
    required this.firstName,
    required this.worker,
    required this.isAvailable,
    required this.hasActiveJobs,
    required this.loading,
    required this.availabilityTourKey,
    required this.onToggleAvailability,
  });

  final String firstName;
  final WorkerModel? worker;
  final bool isAvailable;
  final bool hasActiveJobs;
  final bool loading;
  final GlobalKey availabilityTourKey;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¡Hola de nuevo, $firstName!',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.grayDark,
            ),
          ),
          if (worker != null) ...[
            const SizedBox(height: 4),
            Text(
              worker!.profession,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.grayMedium.withValues(alpha: 0.95),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (worker != null)
                Expanded(
                  child: _HeaderChip(
                    icon: Icons.star_rounded,
                    label: worker!.rating.toStringAsFixed(1),
                    color: AppColors.brandOrange,
                  ),
                ),
              if (worker != null) const SizedBox(width: 8),
              if (!loading)
                TourTarget(
                  tourKey: availabilityTourKey,
                  child: _AvailabilityPill(
                    isAvailable: isAvailable,
                    hasActiveJobs: hasActiveJobs,
                    onTap: onToggleAvailability,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grayMedium.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.grayDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({
    required this.isAvailable,
    required this.hasActiveJobs,
    required this.onTap,
  });

  final bool isAvailable;
  final bool hasActiveJobs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final busy = hasActiveJobs;
    final available = !busy && isAvailable;
    final color = busy
        ? AppColors.warning
        : available
            ? AppColors.success
            : AppColors.grayMedium;
    final bg = busy
        ? AppColors.warning.withValues(alpha: 0.12)
        : available
            ? AppColors.brandOrangeSoft
            : AppColors.grayLight;
    final label = busy
        ? 'Ocupado'
        : available
            ? 'Disponible'
            : 'No disp.';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                available ? Icons.circle : Icons.circle_outlined,
                size: 10,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
