import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

/// Logo de marca compacto para barras y pantallas.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.size = 56,
    this.showText = true,
    this.textSize = 22,
    this.horizontal = false,
    this.forceOnLight,
  });

  final double size;
  final bool showText;
  final double textSize;

  /// Fila icono + texto (home / app bars).
  final bool horizontal;

  /// Si no es null, fuerza contraste sobre fondo claro/oscuro.
  final bool? forceOnLight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onLight = forceOnLight ?? !isDark;
    final markColor = onLight ? AppColors.brandNavy : AppColors.white;

    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandOrangeVibrant, AppColors.brandOrange],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandOrange.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.build_rounded,
        size: size * 0.48,
        color: AppColors.white,
      ),
    );

    final title = Text(
      AppConstants.appBrandDisplayName,
      style: TextStyle(
        fontSize: textSize,
        fontWeight: FontWeight.w800,
        color: markColor,
        letterSpacing: -0.2,
        height: 1.1,
      ),
    );

    if (!showText) return mark;

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.28),
          Flexible(child: title),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.14),
        title,
      ],
    );
  }
}

/// Etiqueta de marca pequeña para pie de pantallas auth.
class AppBrandFooter extends StatelessWidget {
  const AppBrandFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.home_work_outlined, size: 18, color: AppColors.grayMedium),
        SizedBox(width: 6),
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
