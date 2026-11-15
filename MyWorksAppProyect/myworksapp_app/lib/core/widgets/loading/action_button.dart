import 'package:flutter/material.dart';

/// Botón con estado de carga y prevención de doble acción
class ActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const ActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isProcessing = false;

  Future<void> _handlePress() async {
    if (widget.onPressed == null || _isProcessing || widget.isLoading || !widget.isEnabled) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await Future.microtask(() => widget.onPressed!());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.isLoading || _isProcessing;
    final isEnabled = widget.isEnabled && !isLoading;

    return ElevatedButton(
      onPressed: isEnabled ? _handlePress : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: widget.textColor ?? Colors.white,
        disabledBackgroundColor: Colors.grey,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(widget.label),
              ],
            ),
    );
  }
}

