import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';
import '../utils/app_logger.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Servicio global para logout
class LogoutService {
  static final LogoutService instance = LogoutService._();
  LogoutService._();

  /// Ejecuta logout completo y redirige a welcome
  Future<void> logout(WidgetRef ref, BuildContext? context) async {
    try {
      AppLogger.i('Iniciando logout...');

      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.logout();

      AppLogger.i('Logout completado');

      // 4. Redirigir a welcome
      if (context != null && context.mounted) {
        context.go(AppConstants.routeWelcome);
      }
    } catch (e) {
      AppLogger.e('Error durante logout', e);
      // Aún así intentar redirigir
      if (context != null && context.mounted) {
        context.go(AppConstants.routeWelcome);
      }
    }
  }
}

