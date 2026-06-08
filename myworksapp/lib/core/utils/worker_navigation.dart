import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../database/repositories/worker_repository.dart';
import '../utils/constants.dart';

/// Resuelve la ruta inicial del trabajador según su estado de perfil.
Future<void> goToWorkerEntryRoute(BuildContext context, String userId) async {
  final workerRepository = WorkerRepository();
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
}
