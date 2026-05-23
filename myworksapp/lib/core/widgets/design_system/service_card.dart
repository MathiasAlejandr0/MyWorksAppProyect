import 'package:flutter/material.dart';

import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';

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
    final accent = color ?? AppColors.primaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: AppDecorations.surfaceCard(accent: accent),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accent.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 24, color: accent),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
