import 'package:flutter/material.dart';

/// Glifos de marca. Trazo y vacíos propios, no los iconos genéricos de Material.
enum PremiumGlyphKind { location, verified, chat, assembly, electric, plumbing }

class PremiumGlyph extends StatelessWidget {
  const PremiumGlyph({
    super.key,
    required this.kind,
    this.size = 24,
    this.color = const Color(0xFF0A1628),
  });

  final PremiumGlyphKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PremiumGlyphPainter(kind, color),
    );
  }
}

class _PremiumGlyphPainter extends CustomPainter {
  const _PremiumGlyphPainter(this.kind, this.color);

  final PremiumGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 48;
    canvas.save();
    canvas.scale(s);
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case PremiumGlyphKind.location:
        _location(canvas, fill);
      case PremiumGlyphKind.verified:
        _verified(canvas, fill, stroke);
      case PremiumGlyphKind.chat:
        _chat(canvas, fill, stroke);
      case PremiumGlyphKind.assembly:
        _assembly(canvas, stroke);
      case PremiumGlyphKind.electric:
        _electric(canvas, fill);
      case PremiumGlyphKind.plumbing:
        _plumbing(canvas, stroke);
    }
    canvas.restore();
  }

  void _location(Canvas canvas, Paint fill) {
    final pin = Path()
      ..moveTo(24, 6)
      ..cubicTo(34.8, 6, 42, 13.2, 42, 23.2)
      ..cubicTo(42, 31.4, 33.2, 39.6, 24, 44)
      ..cubicTo(14.8, 39.6, 6, 31.4, 6, 23.2)
      ..cubicTo(6, 13.2, 13.2, 6, 24, 6)
      ..close()
      ..addOval(Rect.fromCircle(center: const Offset(24, 22.4), radius: 5.2));
    pin.fillType = PathFillType.evenOdd;
    canvas.drawPath(pin, fill);
    canvas.drawCircle(const Offset(24, 22.4), 1.7, fill);
  }

  void _verified(Canvas canvas, Paint fill, Paint stroke) {
    final shield = Path()
      ..moveTo(24, 5)
      ..lineTo(41, 11.5)
      ..cubicTo(41, 11.5, 41.5, 22, 41, 27.5)
      ..cubicTo(40.2, 35.5, 32.5, 41.8, 24, 44.5)
      ..cubicTo(15.5, 41.8, 7.8, 35.5, 7, 27.5)
      ..cubicTo(6.5, 22, 7, 11.5, 7, 11.5)
      ..close();
    final cut = Paint()
      ..blendMode = BlendMode.dstOut
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFFFFF);

    canvas.saveLayer(const Rect.fromLTWH(0, 0, 48, 48), Paint());
    canvas.drawPath(shield, fill);
    canvas.drawPath(
      Path()
        ..moveTo(24, 11)
        ..lineTo(35.4, 15.4)
        ..cubicTo(35.4, 15.4, 35.6, 22.4, 35.4, 26.2)
        ..cubicTo(34.8, 31.4, 29.6, 35.4, 24, 37.4)
        ..cubicTo(18.4, 35.4, 13.2, 31.4, 12.6, 26.2)
        ..cubicTo(12.4, 22.4, 12.6, 15.4, 12.6, 15.4)
        ..close(),
      cut..strokeWidth = 1.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(16.8, 24.2)
        ..lineTo(22.2, 29.6)
        ..lineTo(31.8, 18.4),
      cut..strokeWidth = 2.6,
    );
    canvas.restore();
    stroke.strokeWidth = 2.4;
  }

  void _chat(Canvas canvas, Paint fill, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 7, 26, 18),
        const Radius.circular(6),
      ),
      stroke..strokeWidth = 2.1,
    );
    final front = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 18, 28, 17),
          const Radius.circular(6),
        ),
      )
      ..moveTo(12, 35)
      ..lineTo(11.2, 41)
      ..lineTo(20, 35)
      ..close();
    final cut = Paint()
      ..blendMode = BlendMode.dstOut
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7
      ..color = const Color(0xFFFFFFFF);
    canvas.saveLayer(const Rect.fromLTWH(0, 0, 48, 48), Paint());
    canvas.drawPath(front, fill);
    canvas.drawLine(const Offset(12, 26.4), const Offset(27, 26.4), cut);
    canvas.restore();
    stroke.strokeWidth = 2.4;
  }

  void _assembly(Canvas canvas, Paint stroke) {
    stroke.strokeWidth = 2.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 10, 32, 28),
        const Radius.circular(3),
      ),
      stroke,
    );
    canvas.drawLine(const Offset(24, 10), const Offset(24, 38), stroke);
    canvas.drawCircle(const Offset(16.5, 24), 1.6, Paint()..color = stroke.color);
    canvas.drawCircle(const Offset(31.5, 24), 1.6, Paint()..color = stroke.color);
    canvas.drawLine(const Offset(14, 16.5), const Offset(20, 16.5), stroke..strokeWidth = 1.6);
  }

  void _electric(Canvas canvas, Paint fill) {
    final bolt = Path()
      ..moveTo(27, 4)
      ..lineTo(12, 26)
      ..lineTo(22.2, 26)
      ..lineTo(18, 44)
      ..lineTo(36.5, 19.5)
      ..lineTo(25.2, 19.5)
      ..close();
    canvas.drawPath(bolt, fill);
  }

  void _plumbing(Canvas canvas, Paint stroke) {
    stroke.strokeWidth = 2.4;
    canvas.drawLine(const Offset(12, 40), const Offset(36, 40), stroke);
    canvas.drawLine(const Offset(22, 40), const Offset(22, 16), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(22, 20)
        ..cubicTo(22, 20, 36, 18, 36, 30),
      stroke,
    );
    canvas.drawLine(const Offset(18, 12), const Offset(26, 16), stroke);
    canvas.drawCircle(const Offset(17.2, 11.2), 2.1, Paint()..color = stroke.color);
  }

  @override
  bool shouldRepaint(covariant _PremiumGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
