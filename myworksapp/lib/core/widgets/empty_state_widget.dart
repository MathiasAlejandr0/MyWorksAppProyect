import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state específico para "No hay trabajos"
class NoJobsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateJob;

  const NoJobsEmptyState({
    super.key,
    this.onCreateJob,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.work_outline,
      title: 'Aún no tienes trabajos',
      message: 'Crea tu primer trabajo y conecta con trabajadores profesionales en tu área.',
      actionLabel: 'Crear Trabajo',
      onAction: onCreateJob,
    );
  }
}

/// Empty state específico para "No hay trabajadores disponibles"
class NoWorkersEmptyState extends StatelessWidget {
  const NoWorkersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.person_search_outlined,
      title: 'No hay trabajadores disponibles',
      message: 'No encontramos trabajadores disponibles en este momento. Intenta más tarde o ajusta tus filtros de búsqueda.',
    );
  }
}

/// Empty state específico para "No hay resultados de búsqueda"
class NoSearchResultsEmptyState extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const NoSearchResultsEmptyState({
    super.key,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No se encontraron resultados',
      message: 'No hay trabajadores que coincidan con tu búsqueda. Intenta ajustar los filtros o buscar con otros términos.',
      actionLabel: 'Limpiar Filtros',
      onAction: onClearFilters,
    );
  }
}
