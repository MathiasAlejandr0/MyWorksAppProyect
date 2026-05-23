import 'package:flutter/material.dart';

import '../../design_system/app_breakpoints.dart';

/// Centra y limita el ancho del contenido en tablet/desktop.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isTablet(context)) {
      return child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
