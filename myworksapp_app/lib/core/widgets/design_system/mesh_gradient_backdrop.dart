import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Fondo limpio con gradiente naranjo y blanco.
class MeshGradientBackdrop extends StatelessWidget {
  const MeshGradientBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _PremiumBackdropPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _PremiumBackdropPainter extends CustomPainter {
  const _PremiumBackdropPainter();

  static const Color _bgTop = AppColors.white;
  static const Color _bgMid = AppColors.brandOrangeSoft;
  static const Color _bgBottom = Color(0xFFFFFAF7);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgMid, _bgBottom],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(1.15, -0.45),
          radius: 0.72,
          colors: [
            AppColors.brandOrange.withValues(alpha: 0.18),
            AppColors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, 1.15),
          radius: 0.65,
          colors: [
            AppColors.brandOrangeSoft.withValues(alpha: 0.55),
            AppColors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumBackdropPainter oldDelegate) => false;
}

/// Superficies para pantallas sobre fondo claro.
class WelcomeSurface {
  WelcomeSurface._();

  static const Color elevated = AppColors.white;
  static const Color elevatedHover = AppColors.brandOrangeSoft;
  static const Color border = Color(0xFFF5D4C0);
  static const Color borderLight = Color(0xFFFBE8DC);
  static const Color textSecondary = AppColors.grayMedium;
  static const Color textMuted = AppColors.grayMedium;

  static BoxDecoration card({Color? accent, double radius = 16}) {
    return BoxDecoration(
      color: elevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accent != null
            ? accent.withValues(alpha: 0.35)
            : border,
        width: 1,
      ),
    );
  }
}
