import 'package:flutter/material.dart';

import '../design_system/app_radius.dart';
import '../design_system/app_spacing.dart';
import '../services/service_legal_validator.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Diálogo de confirmación legal antes de solicitar servicio.
class ServiceDisclaimerDialog extends StatelessWidget {
  final String serviceId;
  final String serviceName;
  final int? chargeAmountClp;

  const ServiceDisclaimerDialog({
    super.key,
    required this.serviceId,
    required this.serviceName,
    this.chargeAmountClp,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.brandOrange),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Confirmación Legal',
              style: AppTextStyles.titleLarge(),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Antes de continuar, debes aceptar lo siguiente:',
              style: AppTextStyles.bodyMedium().copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<String>(
              future: ServiceLegalValidator.instance.buildConfirmationText(
                serviceId: serviceId,
                serviceName: serviceName,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Text(
                  snapshot.data ?? ServiceLegalValidator.platformDisclaimer,
                  style: AppTextStyles.bodySmall(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.payment_outlined,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ServiceLegalValidator.paymentNotice(
                        chargeAmountClp: chargeAmountClp,
                      ),
                      style: AppTextStyles.bodySmall().copyWith(
                        color: AppColors.grayDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Acepto y Continuar'),
        ),
      ],
    );
  }

  static Future<bool> show(
    BuildContext context, {
    required String serviceId,
    required String serviceName,
    int? chargeAmountClp,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ServiceDisclaimerDialog(
        serviceId: serviceId,
        serviceName: serviceName,
        chargeAmountClp: chargeAmountClp,
      ),
    );
    return result ?? false;
  }
}
