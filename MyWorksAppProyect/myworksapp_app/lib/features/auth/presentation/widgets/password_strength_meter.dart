import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    final strength = Validators.passwordStrength(value);
    final color = switch (strength) {
      PasswordStrength.weak => AppColors.error,
      PasswordStrength.medium => AppColors.warning,
      PasswordStrength.strong => AppColors.success,
    };
    final label = switch (strength) {
      PasswordStrength.weak => 'Débil',
      PasswordStrength.medium => 'Media',
      PasswordStrength.strong => 'Alta',
    };
    final progress = switch (strength) {
      PasswordStrength.weak => 0.33,
      PasswordStrength.medium => 0.66,
      PasswordStrength.strong => 1.0,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: color,
              backgroundColor: AppColors.hairlineOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seguridad: $label — mínimo 8 caracteres, letra y número',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
