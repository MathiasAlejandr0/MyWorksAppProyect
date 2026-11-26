import 'package:flutter/widgets.dart';

/// Libera los controladores de un diálogo cuando el diálogo se desmonta.
///
/// `showDialog` completa su `Future` apenas se hace `pop`, pero el diálogo
/// sigue montado mientras anima su salida y sus `TextField` todavía usan los
/// controladores. Liberarlos justo después del `await` produce el error
/// «A TextEditingController was used after being disposed». Envolver el
/// contenido del diálogo con este widget los libera recién al desmontarse.
class DialogControllersScope extends StatefulWidget {
  const DialogControllersScope({
    super.key,
    required this.controllers,
    required this.child,
  });

  final List<ChangeNotifier> controllers;
  final Widget child;

  @override
  State<DialogControllersScope> createState() => _DialogControllersScopeState();
}

class _DialogControllersScopeState extends State<DialogControllersScope> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
