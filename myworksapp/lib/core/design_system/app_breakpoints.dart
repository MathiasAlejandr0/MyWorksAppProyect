import 'package:flutter/material.dart';

/// Breakpoints y utilidades responsive (Material 3 / Flutter).
class AppBreakpoints {
  AppBreakpoints._();

  /// Ancho mínimo del lado corto para considerar tablet.
  static const double tablet = 600;

  /// Ancho mínimo para layout amplio (desktop / tablet landscape grande).
  static const double desktop = 1024;

  /// Ancho máximo del contenido centrado en pantallas grandes.
  static const double contentMaxWidth = 720;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) => MediaQuery.sizeOf(context).height;

  static double shortestSideOf(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide;

  static bool isTablet(BuildContext context) => shortestSideOf(context) >= tablet;

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktop;

  /// Padding horizontal según tamaño de pantalla.
  static double screenPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  /// Columnas de grid según ancho disponible.
  static int gridColumns(
    BuildContext context, {
    int phone = 2,
    int tablet = 3,
    int desktopCols = 4,
  }) {
    if (isDesktop(context)) return desktopCols;
    if (isTablet(context)) return tablet;
    return phone;
  }
}
