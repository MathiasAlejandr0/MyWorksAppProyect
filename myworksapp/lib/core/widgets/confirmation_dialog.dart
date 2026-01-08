import 'package:flutter/material.dart';

/// Dialog de confirmación claro y humano
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  /// Muestra el dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
  }) async {
    bool? result;
    await showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => result = true,
      ),
    );
    return result;
  }
}

/// Dialog de confirmación para cancelar trabajo
class CancelJobDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const CancelJobDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: '¿Cancelar este trabajo?',
      message: 'Si cancelas este trabajo, el trabajador será notificado y el trabajo se marcará como cancelado. Esta acción no se puede deshacer.',
      confirmLabel: 'Sí, cancelar',
      cancelLabel: 'No, mantener',
      isDestructive: true,
      onConfirm: onConfirm,
    );
  }

  static Future<bool?> show(BuildContext context) {
    return ConfirmationDialog.show(
      context,
      title: '¿Cancelar este trabajo?',
      message: 'Si cancelas este trabajo, el trabajador será notificado y el trabajo se marcará como cancelado. Esta acción no se puede deshacer.',
      confirmLabel: 'Sí, cancelar',
      cancelLabel: 'No, mantener',
      isDestructive: true,
    );
  }
}

