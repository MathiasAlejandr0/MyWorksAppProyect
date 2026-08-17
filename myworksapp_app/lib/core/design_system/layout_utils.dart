import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Utilidades de layout compartidas entre pantallas.
class LayoutUtils {
  LayoutUtils._();

  /// Padding horizontal estándar + margen inferior seguro para scrolls con CTA.
  static EdgeInsets scrollPadding(
    BuildContext context, {
    double top = AppSpacing.md,
    double extraBottom = 0,
  }) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      top,
      AppSpacing.screenPadding,
      AppSpacing.screenPadding + safeBottom + extraBottom,
    );
  }

  static EdgeInsets get screenHorizontal =>
      const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);
}
