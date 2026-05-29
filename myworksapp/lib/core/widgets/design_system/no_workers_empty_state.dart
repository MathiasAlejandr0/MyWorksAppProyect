import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../../widgets/design_system/primary_button.dart';
import '../../widgets/design_system/secondary_button.dart';
/// Empty state específico para "Sin trabajadores disponibles"
class NoWorkersEmptyState extends StatelessWidget {
  final String? message;
  final bool hasFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onScheduleLater;
  final VoidCallback? onExpandSearch;

  const NoWorkersEmptyState({
    super.key,
    this.message,
    this.hasFilters = false,
    this.onClearFilters,
    this.onScheduleLater,
    this.onExpandSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 80,
              color: AppColors.grayMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message ?? 'No hay trabajadores disponibles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.grayDark,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilters
                  ? 'Intenta quitar algunos filtros para ver más resultados'
                  : 'Puede que no haya trabajadores disponibles en este momento. Intenta más tarde o amplía tu búsqueda.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grayMedium,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (hasFilters && onClearFilters != null) ...[
              PrimaryButton(
                label: 'Quitar Filtros',
                onPressed: onClearFilters,
                icon: Icons.filter_alt_off,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (onScheduleLater != null) ...[
              SecondaryButton(
                label: 'Agendar para Más Tarde',
                onPressed: onScheduleLater,
                icon: Icons.schedule,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (onExpandSearch != null) ...[
              SecondaryButton(
                label: 'Ampliar Búsqueda',
                onPressed: onExpandSearch,
                icon: Icons.search,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

