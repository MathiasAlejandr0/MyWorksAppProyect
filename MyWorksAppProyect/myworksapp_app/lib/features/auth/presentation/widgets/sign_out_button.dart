import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/logout_service.dart';
import '../../../../core/theme/app_colors.dart';

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key, this.label = 'Cerrar sesión'});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmAndSignOut(context, ref),
      icon: const Icon(Icons.logout_rounded),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  static Future<void> _confirmAndSignOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await LogoutService.instance.logout(ref, context);
    }
  }
}
