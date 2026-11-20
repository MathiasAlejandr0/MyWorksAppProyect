import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/job_status_copy.dart';
import '../../../jobs/presentation/widgets/job_status_timeline.dart';
import '../../../notifications/domain/notification_groups.dart';

/// Carta del inicio del cliente cuando hay un trabajo `en_curso`.
class InProgressJobCard extends StatelessWidget {
  const InProgressJobCard({
    super.key,
    required this.serviceName,
    required this.description,
    required this.address,
    required this.status,
    required this.onOpen,
  });

  final String? serviceName;
  final String? description;
  final String address;
  final String status;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final label = labelForJob(
      serviceName: serviceName,
      description: description,
      address: address,
    );
    final step = jobProgressStep(status);
    final total = jobTimelineSteps.length;
    final percent = (jobProgressFraction(status) * 100).round();
    final next = jobProgressNextStatus(status);
    final statusLabel = JobStatusCopy.label(status);

    return Semantics(
      container: true,
      label: 'Trabajo en curso, ${label.title}, avance $percent por ciento',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: AppDecorations.surfaceCardOf(
          context,
          accent: AppColors.brandOrange,
          radius: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.handyman_outlined,
                    color: AppColors.brandOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Trabajo en curso',
                    style: TextStyle(
                      color: AppColors.brandOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.2,
              ),
            ),
            if (label.detail != null) ...[
              const SizedBox(height: 2),
              Text(
                label.detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontSize: 13, height: 1.3),
              ),
            ],
            const SizedBox(height: 14),
            _ProgressSegments(
              filled: step,
              total: total,
              track: muted.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 8),
            Text(
              step == 0
                  ? statusLabel
                  : 'Paso $step de $total · $statusLabel',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 2),
              Text(
                'Siguiente: ${JobStatusCopy.label(next)}',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onOpen,
              child: const Text('Ver trabajo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({
    required this.filled,
    required this.total,
    required this.track,
  });

  final int filled;
  final int total;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final count = total <= 0 ? 1 : total;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < filled ? AppColors.brandOrange : track,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
