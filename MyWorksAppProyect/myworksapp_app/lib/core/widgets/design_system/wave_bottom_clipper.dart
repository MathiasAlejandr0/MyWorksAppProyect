import 'package:flutter/material.dart';

/// Recorte con curva suave en la parte inferior (estilo mockup welcome).
class WaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 48);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 28,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      size.height - 56,
      size.width,
      size.height - 36,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
