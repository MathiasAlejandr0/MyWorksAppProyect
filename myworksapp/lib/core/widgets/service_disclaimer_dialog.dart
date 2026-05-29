import 'package:flutter/material.dart';
import '../services/service_legal_validator.dart';
import '../theme/app_text_styles.dart';

/// Diálogo de confirmación legal antes de solicitar servicio
/// 
/// Muestra el descargo de responsabilidad y requiere aceptación explícita.
class ServiceDisclaimerDialog extends StatelessWidget {
  final String serviceId;
  final String serviceName;

  const ServiceDisclaimerDialog({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 8),
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
            const SizedBox(height: 16),
            _buildDisclaimerSection(
              'Naturaleza de la Plataforma',
              ServiceLegalValidator.platformDisclaimer,
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: ServiceLegalValidator.instance.getServiceDisclaimer(serviceId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return _buildDisclaimerSection(
                    'Descargo Específico - $serviceName',
                    snapshot.data!,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El pago se realiza directamente con el trabajador. My Works App no procesa pagos en esta etapa.',
                      style: AppTextStyles.bodySmall().copyWith(
                        color: Colors.orange.shade900,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Acepto y Continuar'),
        ),
      ],
    );
  }

  Widget _buildDisclaimerSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall().copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppTextStyles.bodySmall(),
        ),
      ],
    );
  }

  /// Muestra el diálogo y retorna true si el usuario acepta
  static Future<bool> show(BuildContext context, {
    required String serviceId,
    required String serviceName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ServiceDisclaimerDialog(
        serviceId: serviceId,
        serviceName: serviceName,
      ),
    );
    return result ?? false;
  }
}

