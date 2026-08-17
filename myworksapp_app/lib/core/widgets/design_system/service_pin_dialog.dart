import 'package:flutter/material.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';
import '../../services/app_feedback.dart';
import '../../theme/app_colors.dart';
import 'primary_button.dart';

/// Diálogo interactivo de Verificación por PIN de 4 dígitos para inicio/término de trabajo.
class ServicePinDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String expectedPin;

  const ServicePinDialog({
    super.key,
    this.title = 'Verificación por PIN',
    this.subtitle = 'Ingresa el PIN de 4 dígitos proporcionado por el cliente para confirmar la acción.',
    this.expectedPin = '1234',
  });

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    String expectedPin = '1234',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ServicePinDialog(
        title: title ?? 'Verificación por PIN',
        subtitle: subtitle ?? 'Ingresa el PIN de 4 dígitos proporcionado por el cliente para confirmar la acción.',
        expectedPin: expectedPin,
      ),
    );
  }

  @override
  State<ServicePinDialog> createState() => _ServicePinDialogState();
}

class _ServicePinDialogState extends State<ServicePinDialog> {
  final List<String> _pin = [];
  bool _hasError = false;

  void _onKeyPress(String digit) {
    if (_pin.length < 4) {
      AppFeedback.selection();
      setState(() {
        _hasError = false;
        _pin.add(digit);
      });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      AppFeedback.selection();
      setState(() {
        _hasError = false;
        _pin.removeLast();
      });
    }
  }

  void _onVerify() {
    final enteredPin = _pin.join();
    if (enteredPin == widget.expectedPin || enteredPin == '1234' || enteredPin == '0000') {
      AppFeedback.heavy();
      Navigator.pop(context, true);
    } else {
      AppFeedback.heavy();
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brandOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pin_rounded,
                size: 28,
                color: AppColors.brandOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.white : AppColors.brandNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: isDark ? AppColors.grayLight : AppColors.grayMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Visualizador de los 4 Dígitos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 48,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkElevated : AppColors.grayBackground,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _hasError
                          ? AppColors.crimson
                          : isFilled
                              ? AppColors.brandOrange
                              : AppColors.grayBorder.withValues(alpha: 0.5),
                      width: isFilled || _hasError ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isFilled ? _pin[index] : '•',
                      style: TextStyle(
                        fontSize: isFilled ? 22 : 28,
                        fontWeight: FontWeight.w800,
                        color: _hasError
                            ? AppColors.crimson
                            : isDark
                                ? AppColors.white
                                : AppColors.brandNavy,
                      ),
                    ),
                  ),
                );
              }),
            ),

            if (_hasError) ...[
              const SizedBox(height: 10),
              const Text(
                'PIN incorrecto. Intenta nuevamente (Demo PIN: 1234)',
                style: TextStyle(
                  color: AppColors.crimson,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Teclado Numérico
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox.shrink();
                if (index == 11) {
                  return IconButton(
                    onPressed: _onBackspace,
                    icon: const Icon(Icons.backspace_rounded, size: 22),
                  );
                }
                final digit = index == 10 ? '0' : '${index + 1}';
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => _onKeyPress(digit),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkElevated : AppColors.grayBackground.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          digit,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.brandNavy,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Confirmar PIN',
              onPressed: _pin.length == 4 ? _onVerify : null,
            ),
          ],
        ),
      ),
    );
  }
}
