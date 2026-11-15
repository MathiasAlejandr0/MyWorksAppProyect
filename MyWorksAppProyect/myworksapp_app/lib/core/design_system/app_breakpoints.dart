import 'package:flutter/material.dart';

/// Breakpoints y utilidades responsive (teléfono, tablet, escritorio).
class AppBreakpoints {
  AppBreakpoints._();

  /// Lado corto mínimo para considerar tablet (Material guideline).
  static const double tablet = 600;

  /// Ancho mínimo para layout amplio (desktop / tablet landscape grande).
  static const double desktop = 1024;

  /// Ancho máximo del contenido en tablet.
  static const double contentMaxWidthTablet = 840;

  /// Ancho máximo del contenido en escritorio / tablet grande.
  static const double contentMaxWidthDesktop = 1100;

  @Deprecated('Usar contentMaxWidthTablet o contentMaxWidthDesktop')
  static const double contentMaxWidth = contentMaxWidthTablet;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) => MediaQuery.sizeOf(context).height;

  static double shortestSideOf(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide;

  static bool isPhone(BuildContext context) => shortestSideOf(context) < tablet;

  static bool isTablet(BuildContext context) {
    final shortest = shortestSideOf(context);
    return shortest >= tablet && widthOf(context) < desktop;
  }

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktop;

  static bool isLargeScreen(BuildContext context) => shortestSideOf(context) >= tablet;

  static double contentMaxWidthFor(BuildContext context) {
    if (isDesktop(context)) return contentMaxWidthDesktop;
    if (isTablet(context)) return contentMaxWidthTablet;
    return widthOf(context);
  }

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
    if (isLargeScreen(context)) return tablet;
    return phone;
  }

  /// Altura máxima para imágenes hero en pantallas grandes.
  static double heroImageHeight(BuildContext context, {double phoneRatio = 0.52}) {
    final width = widthOf(context);
    if (isDesktop(context)) return 380;
    if (isTablet(context)) return 340;
    return width * phoneRatio;
  }
}
