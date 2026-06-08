import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';

/// Botón secundario del Design System (outlined)
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: Semantics(
        label: label,
        button: true,
        enabled: onPressed != null && !isLoading,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandOrange,
          side: const BorderSide(color: AppColors.brandOrange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandOrange),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

