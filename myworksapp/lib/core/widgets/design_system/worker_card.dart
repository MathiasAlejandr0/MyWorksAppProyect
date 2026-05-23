import 'package:flutter/material.dart';

import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';

/// Card para trabajadores
class WorkerCard extends StatelessWidget {
  final String name;
  final String profession;
  final double? rating;
  final String? avatarUrl;
  final bool isAvailable;
  final VoidCallback? onTap;

  const WorkerCard({
    super.key,
    required this.name,
    required this.profession,
    this.rating,
    this.avatarUrl,
    this.isAvailable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecorations.surfaceCard(
        accent: isAvailable ? AppColors.success : AppColors.grayMedium,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.12),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w800,
                              ),
                        )
                      : null,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        profession,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grayMedium,
                            ),
                      ),
                      if (rating != null) ...[
                        SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.warning),
                            SizedBox(width: AppSpacing.xs),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (isAvailable ? AppColors.success : AppColors.grayMedium)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Disponible' : 'Ocupado',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              isAvailable ? AppColors.success : AppColors.grayMedium,
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
