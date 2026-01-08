import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_elevation.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';

/// Card para servicios
class ServiceCard extends StatelessWidget {
  final String name;
  final String? description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const ServiceCard({
    super.key,
    required this.name,
    this.description,
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primaryLight;
    
    return Card(
      elevation: AppElevation.card,
      margin: EdgeInsets.all(AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: cardColor,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              if (description != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

