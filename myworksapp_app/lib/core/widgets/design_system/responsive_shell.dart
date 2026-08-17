import 'package:flutter/material.dart';

import '../../design_system/app_breakpoints.dart';

/// Centra y limita el ancho del contenido en tablet y escritorio.
/// En teléfonos deja el layout a ancho completo.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isPhone(context)) {
      return child;
    }

    final padding = AppBreakpoints.screenPadding(context);
    final maxWidth = AppBreakpoints.contentMaxWidthFor(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
