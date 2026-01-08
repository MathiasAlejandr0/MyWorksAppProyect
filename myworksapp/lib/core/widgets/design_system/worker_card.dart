import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_elevation.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';

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
    return Card(
      elevation: AppElevation.card,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: AppSpacing.lg),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                          Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Estado de disponibilidad
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.grayMedium.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAvailable ? 'Disponible' : 'Ocupado',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isAvailable ? AppColors.success : AppColors.grayMedium,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

