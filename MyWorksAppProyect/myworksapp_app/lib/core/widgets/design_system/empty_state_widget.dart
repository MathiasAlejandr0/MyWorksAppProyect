import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';

/// Widget para estados vacíos
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.white : AppColors.brandNavy;
    final messageColor = isDark
        ? AppColors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;
    final glyphColor = iconColor ??
        (isDark
            ? AppColors.brandOrange.withValues(alpha: 0.75)
            : AppColors.grayMedium);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandOrange.withValues(
                  alpha: isDark ? 0.16 : 0.1,
                ),
              ),
              child: Icon(icon, size: 34, color: glyphColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: messageColor,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

