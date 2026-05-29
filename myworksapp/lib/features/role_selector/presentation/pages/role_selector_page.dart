import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';

class RoleSelectorPage extends StatelessWidget {
  const RoleSelectorPage({super.key});

  Future<void> _saveRoleAndNavigate(BuildContext context, String role) async {
    // Guardar el rol seleccionado (se guardará cuando el usuario se registre)
    // Por ahora, navegamos al login/registro
    context.push(
      AppConstants.routeLogin,
      extra: {'role': role},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Selecciona tu rol'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Cómo quieres usar la app?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Botón Usuario
              _RoleCard(
                icon: Icons.person,
                title: 'Usuario',
                description: 'Busco servicios profesionales',
                color: AppColors.primaryLight,
                onTap: () => _saveRoleAndNavigate(context, AppConstants.roleUser),
              ),
              const SizedBox(height: 24),
              // Botón Trabajador
              _RoleCard(
                icon: Icons.build,
                title: 'Trabajador',
                description: 'Ofrezco servicios profesionales',
                color: AppColors.success,
                onTap: () => _saveRoleAndNavigate(context, AppConstants.roleWorker),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grayMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

