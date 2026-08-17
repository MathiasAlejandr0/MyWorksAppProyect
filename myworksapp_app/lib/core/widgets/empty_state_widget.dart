import 'package:flutter/material.dart';

import 'design_system/empty_state_widget.dart' as ds;

export 'design_system/empty_state_widget.dart';

/// Estados vacíos especializados que reutilizan el widget del design system.
class NoJobsEmptyState extends StatelessWidget {
  final VoidCallback? onCreateJob;

  const NoJobsEmptyState({super.key, this.onCreateJob});

  @override
  Widget build(BuildContext context) {
    return ds.EmptyStateWidget(
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
    return const ds.EmptyStateWidget(
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
    return ds.EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No se encontraron resultados',
      message:
          'No hay trabajadores que coincidan con tu búsqueda. Prueba con otros términos.',
      actionLabel: 'Limpiar filtros',
      onAction: onClearFilters,
    );
  }
}
