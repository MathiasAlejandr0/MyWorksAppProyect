import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';

/// Widget de empty state educacional
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: AppDecorations.surfaceCard(accent: AppColors.primaryLight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 32, color: AppColors.primaryLight),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grayMedium,
                    ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NoJobsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateJob;

  const NoJobsEmptyState({super.key, this.onCreateJob});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.work_outline_rounded,
      title: 'Aún no tienes trabajos',
      message:
          'Crea tu primer trabajo y conecta con trabajadores profesionales en tu área.',
      actionLabel: 'Crear Trabajo',
      onAction: onCreateJob,
    );
  }
}

class NoWorkersEmptyState extends StatelessWidget {
  const NoWorkersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.person_search_outlined,
      title: 'No hay trabajadores disponibles',
      message:
          'No encontramos trabajadores disponibles en este momento. Intenta más tarde o ajusta tus filtros.',
    );
  }
}

class NoSearchResultsEmptyState extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const NoSearchResultsEmptyState({super.key, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No se encontraron resultados',
      message:
          'No hay trabajadores que coincidan con tu búsqueda. Prueba con otros términos.',
      actionLabel: 'Limpiar filtros',
      onAction: onClearFilters,
    );
  }
}
