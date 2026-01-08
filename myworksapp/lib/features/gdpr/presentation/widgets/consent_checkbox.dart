import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../pages/privacy_policy_page.dart';
import '../pages/terms_page.dart';

/// Widget de checkbox de consentimiento GDPR
/// 
/// Muestra checkbox obligatorio con enlaces a términos y política de privacidad.
/// Cumple con GDPR - Consentimiento explícito e informado.
class ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String consentVersion;

  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.consentVersion = '1.0',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: value,
                  onChanged: (newValue) => onChanged(newValue ?? false),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acepto los términos y condiciones',
                        style: AppTextStyles.bodyMedium(),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.push(AppConstants.routeTerms);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Términos y Condiciones',
                              style: AppTextStyles.bodySmall().copyWith(
                                decoration: TextDecoration.underline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            'y la',
                            style: AppTextStyles.bodySmall(),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push(AppConstants.routePrivacyPolicy);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Política de Privacidad',
                              style: AppTextStyles.bodySmall().copyWith(
                                decoration: TextDecoration.underline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este consentimiento es obligatorio para usar la aplicación.',
                        style: AppTextStyles.bodySmall().copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

