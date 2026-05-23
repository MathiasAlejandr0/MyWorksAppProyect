import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? accentColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primaryLight;

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: AppDecorations.surfaceCard(accent: accent),
      child: Material(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
