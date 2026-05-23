import 'package:flutter/material.dart';

/// Límites de escala de texto para accesibilidad sin romper layouts.
class AppTextScaling {
  AppTextScaling._();

  static const double minScale = 0.85;
  static const double maxScale = 1.4;

  static TextScaler clamp(TextScaler scaler) =>
      scaler.clamp(minScaleFactor: minScale, maxScaleFactor: maxScale);

  static MediaQueryData apply(MediaQueryData data) =>
      data.copyWith(textScaler: clamp(data.textScaler));
}
