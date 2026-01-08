import 'package:flutter/material.dart';

/// Elevaciones estándar del Design System
class AppElevation {
  AppElevation._();

  // Niveles de elevación (0-4)
  static const double level0 = 0.0;
  static const double level1 = 2.0;
  static const double level2 = 4.0;
  static const double level3 = 8.0;
  static const double level4 = 16.0;

  // Elevaciones específicas
  static const double card = level1;
  static const double button = level1;
  static const double dialog = level4;
  static const double appBar = level0;
  static const double bottomSheet = level3;
}

