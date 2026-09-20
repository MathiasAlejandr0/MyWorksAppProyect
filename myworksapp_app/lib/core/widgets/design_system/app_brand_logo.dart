import 'dart:math' as math;

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
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final mark = SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        maxWidth: size * dpr,
        maxHeight: size * dpr,
        alignment: Alignment.center,
        child: Transform.scale(
          scale: 1 / dpr,
          child: CustomPaint(
            size: Size(size * dpr, size * dpr),
            painter: const _BrandMarkPainter(),
          ),
        ),
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
        SizedBox(
          width: 18,
          height: 18,
          child: CustomPaint(painter: _BrandMarkPainter()),
        ),
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

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  static const double _viewW = 163.6;
  static const double _viewH = 166.48;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _viewW, size.height / _viewH);
    canvas.save();
    canvas.translate((size.width - _viewW * s) / 2, (size.height - _viewH * s) / 2);
    canvas.scale(s);

    final orange = Paint()
      ..color = const Color(0xFFFF5E03)
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    final navy = Paint()
      ..color = const Color(0xFF00205B)
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    final letter = Paint()
      ..color = const Color(0xFFF7F8FA)
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(73.6, 14.08, 86.64, 143.04),
        const Radius.circular(13.44),
      ),
      orange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14.08, 27.28, 85.92, 136.32),
        const Radius.circular(13.44),
      ),
      navy,
    );

    canvas.drawPath(
      Path()
        ..moveTo(34.0, 58.24)
        ..lineTo(34.72, 56.56)
        ..lineTo(51.28, 56.8)
        ..lineTo(76.48, 98.8)
        ..lineTo(95.44, 61.6)
        ..lineTo(96.4, 59.92)
        ..lineTo(98.08, 59.92)
        ..lineTo(125.68, 110.56)
        ..lineTo(126.16, 57.28)
        ..lineTo(140.32, 56.8)
        ..lineTo(140.8, 61.6)
        ..lineTo(140.56, 128.8)
        ..lineTo(119.68, 129.04)
        ..lineTo(97.84, 88.72)
        ..lineTo(96.88, 89.44)
        ..lineTo(88.48, 106.96)
        ..lineTo(88.72, 108.16)
        ..lineTo(88.0, 108.4)
        ..lineTo(78.88, 127.36)
        ..lineTo(76.96, 127.6)
        ..lineTo(49.6, 81.76)
        ..lineTo(49.36, 128.32)
        ..lineTo(48.64, 129.28)
        ..lineTo(34.96, 129.28)
        ..lineTo(34.24, 128.56)
        ..close(),
      letter,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
