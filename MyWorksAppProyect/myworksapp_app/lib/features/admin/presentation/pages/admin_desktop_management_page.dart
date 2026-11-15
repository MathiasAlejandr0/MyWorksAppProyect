import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';

/// El panel del teléfono no reemplaza al programa de escritorio.
class AdminDesktopManagementPage extends StatelessWidget {
  const AdminDesktopManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(
        title: Text('Programa de escritorio'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'La liquidación, las disputas y el soporte se operan en la aplicación de escritorio, con los pagos retenidos de verdad.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Esta pantalla del teléfono no muestra casos de ejemplo. Abre el programa de escritorio con la cuenta de administrador para liberar un pago o resolver un reclamo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => context.go(AppConstants.routeAdminDashboard),
            child: const Text('Volver al panel'),
          ),
        ],
      ),
    );
  }
}
