import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

/// Logo de marca: casa + herramienta, como en los mockups.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.size = 56,
    this.showText = true,
    this.textSize = 22,
  });

  final double size;
  final bool showText;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.home_rounded,
                size: size * 0.92,
                color: AppColors.brandNavy,
              ),
              Positioned(
                bottom: size * 0.08,
                child: Icon(
                  Icons.build_rounded,
                  size: size * 0.38,
                  color: AppColors.brandOrange,
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.12),
          Text(
            AppConstants.appBrandDisplayName,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w800,
              color: AppColors.brandNavy,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

/// Etiqueta de marca pequeña para pie de pantallas auth.
class AppBrandFooter extends StatelessWidget {
  const AppBrandFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.home_work_outlined, size: 18, color: AppColors.grayMedium),
        const SizedBox(width: 6),
        Text(
          AppConstants.appBrandDisplayName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grayMedium,
          ),
        ),
      ],
    );
  }
}
