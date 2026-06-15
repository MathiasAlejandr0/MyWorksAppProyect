import 'package:flutter/material.dart';

import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';

/// Badge opcional para chips en tarjetas de trabajador.
class WorkerCardBadge {
  const WorkerCardBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

/// Card para trabajadores en listados.
class WorkerCard extends StatelessWidget {
  final String name;
  final String profession;
  final double? rating;
  final String? avatarUrl;
  final bool isAvailable;
  final VoidCallback? onTap;
  final Widget? leading;
  final String? headerBadge;
  final Color? headerBadgeColor;
  final List<WorkerCardBadge>? badges;
  final bool showChevron;
  final EdgeInsetsGeometry? margin;

  const WorkerCard({
    super.key,
    required this.name,
    required this.profession,
    this.rating,
    this.avatarUrl,
    this.isAvailable = true,
    this.onTap,
    this.leading,
    this.headerBadge,
    this.headerBadgeColor,
    this.badges,
    this.showChevron = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isAvailable ? AppColors.primaryLight : AppColors.grayMedium;

    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.sm,
          ),
      decoration: AppDecorations.surfaceCard(accent: accent),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            child: Row(
              children: [
                leading ??
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.12),
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                            )
                          : null,
                    ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (headerBadge != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            headerBadge!,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: headerBadgeColor ?? AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profession,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grayMedium,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (badges != null && badges!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs + 2),
                        Wrap(
                          spacing: AppSpacing.xs + 2,
                          runSpacing: AppSpacing.xs,
                          children: badges!
                              .map((b) => _ChipBadge(
                                    icon: b.icon,
                                    label: b.label,
                                    color: b.color,
                                  ))
                              .toList(),
                        ),
                      ] else if (rating != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (showChevron)
                  const Icon(Icons.chevron_right_rounded, color: AppColors.grayMedium)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: (isAvailable
                              ? AppColors.success
                              : AppColors.grayMedium)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      isAvailable ? 'Disponible' : 'Ocupado',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isAvailable
                                ? AppColors.success
                                : AppColors.grayMedium,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
