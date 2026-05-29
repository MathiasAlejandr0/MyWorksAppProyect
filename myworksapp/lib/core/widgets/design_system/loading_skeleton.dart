import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../theme/app_colors.dart';

/// Skeleton loader para estados de carga
class LoadingSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton para cards de lista
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            LoadingSkeleton(
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(28),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(height: 16),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 14, width: 150),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

