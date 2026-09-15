import 'package:flutter/material.dart';

import '../../../../core/database/models/worker_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_guided_tour.dart';

/// Cabecera trabajador — saludo alineado a la izquierda (mockup premium).
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
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final mutedColor = AppColors.onCanvasMuted(brightness);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola de nuevo, $firstName!',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.15,
              color: titleColor,
            ),
          ),
          if (worker != null) ...[
            const SizedBox(height: 6),
            Text(
              worker!.profession,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (worker != null)
                _HeaderChip(
                  icon: Icons.star_rounded,
                  label: worker!.rating.toStringAsFixed(1),
                  accent: AppColors.brandOrange,
                ),
              if (worker != null) const SizedBox(width: 10),
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
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.onCanvas(Theme.of(context).brightness);
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.fieldFillOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.hairlineOf(context, accent: accent),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: muted,
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
    final available = isAvailable && !hasActiveJobs;
    final border = available ? AppColors.emerald : AppColors.brandOrange;
    final label = hasActiveJobs
        ? 'Ocupado'
        : (isAvailable ? 'Disponible' : 'No disponible');
    final textColor = available
        ? AppColors.emerald
        : AppColors.onCanvas(Theme.of(context).brightness);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.fieldFillOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.hairlineOf(context, accent: border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: border,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
