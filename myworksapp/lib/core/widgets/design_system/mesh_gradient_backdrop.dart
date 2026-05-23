import 'package:flutter/material.dart';

/// Fondo limpio sin blur: gradientes nítidos y acentos suaves pintados en canvas.
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

  static const Color _bgTop = Color(0xFF0B1524);
  static const Color _bgMid = Color(0xFF0A1628);
  static const Color _bgBottom = Color(0xFF08111E);

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

    // Acento superior derecho — tono azul definido, muy contenido
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(1.15, -0.45),
          radius: 0.72,
          colors: [
            const Color(0xFF1A3D5C).withValues(alpha: 0.55),
            const Color(0xFF0A1628).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect),
    );

    // Acento inferior izquierdo — verde muy sutil
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, 1.15),
          radius: 0.65,
          colors: [
            const Color(0xFF0F3D32).withValues(alpha: 0.35),
            const Color(0xFF08111E).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect),
    );

    // Línea de luz superior fina
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    // Viñeta ligera en bordes
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.28),
          ],
          stops: const [0.72, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumBackdropPainter oldDelegate) => false;
}

/// Superficies sólidas para pantallas sobre fondo oscuro (sin glass/blur).
class WelcomeSurface {
  WelcomeSurface._();

  static const Color elevated = Color(0xFF0F1F35);
  static const Color elevatedHover = Color(0xFF132338);
  static const Color border = Color(0xFF1E3352);
  static const Color borderLight = Color(0xFF2A4568);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

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
