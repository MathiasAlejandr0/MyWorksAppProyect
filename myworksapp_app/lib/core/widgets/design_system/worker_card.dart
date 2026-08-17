import 'package:flutter/material.dart';

import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';
import 'apple_card.dart';

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

/// Card para trabajadores en listados con estética Apple HIG.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isAvailable ? AppColors.brandOrange : AppColors.grayMedium;

    return AppleCard(
      onTap: onTap,
      margin: margin,
      accentColor: accentColor,
      child: Row(
        children: [
          leading ??
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark
                        ? AppColors.surfaceDarkElevated
                        : AppColors.brandOrangeSoft,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.brandOrange,
                                  fontWeight: FontWeight.w700,
                                ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isAvailable ? AppColors.success : AppColors.grayMedium,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.surfaceDark : AppColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headerBadge != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      headerBadge!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: headerBadgeColor ?? AppColors.success,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  profession,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (badges != null && badges!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs + 2),
                  Wrap(
                    spacing: AppSpacing.xs,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (showChevron)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: (isAvailable ? AppColors.success : AppColors.grayMedium)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                isAvailable ? 'Disponible' : 'Ocupado',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isAvailable ? AppColors.success : AppColors.grayMedium,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
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
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

