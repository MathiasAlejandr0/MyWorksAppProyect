import 'package:flutter/material.dart';

import 'design_system/error_state_widget.dart';

/// Compatibilidad con pantallas que usan el widget legacy de error.
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Algo salió mal',
      message: message,
      actionLabel: onRetry != null ? 'Reintentar' : null,
      onRetry: onRetry,
    );
  }
}
