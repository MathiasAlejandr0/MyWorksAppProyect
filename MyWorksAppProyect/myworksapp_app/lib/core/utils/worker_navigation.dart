import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../database/repositories/worker_repository.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';

/// Resuelve la ruta inicial del trabajador según su estado de perfil.
///
/// Si la ficha no responde, se entra al inicio. Quedarse en el login hacía
/// parecer que el correo y la contraseña no servían.
Future<void> goToWorkerEntryRoute(BuildContext context, String userId) async {
  final workerRepository = WorkerRepository();
  try {
    final worker = await workerRepository.getWorkerByUserId(userId);
    if (!context.mounted) return;
    if (worker == null) {
      context.go(AppConstants.routeWorkerRegister);
      return;
    }
    if (!worker.pricingConfigured) {
      context.go(AppConstants.routeWorkerPricingSetup);
      return;
    }
    context.go(AppConstants.routeWorkerHome);
  } catch (e, st) {
    AppLogger.e('No se pudo leer la ficha al entrar', e, st);
    if (context.mounted) context.go(AppConstants.routeWorkerHome);
  }
}
