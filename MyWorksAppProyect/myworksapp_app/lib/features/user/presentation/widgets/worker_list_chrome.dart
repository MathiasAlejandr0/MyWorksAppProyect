import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';

class WorkerListFilters extends StatelessWidget {
  const WorkerListFilters({
    super.key,
    required this.searchController,
    required this.sortBy,
    required this.minRating,
    required this.onSortChanged,
    required this.onMinRatingChanged,
  });

  final TextEditingController searchController;
  final String sortBy;
  final double minRating;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<double> onMinRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o profesión...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.clear),
                      onPressed: searchController.clear,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Ordenar por',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'cercania',
                      child: Text('Cercanía, nota y precio', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(value: 'precio', child: Text('Precio')),
                    DropdownMenuItem(value: 'calificacion', child: Text('Calificación')),
                  ],
                  onChanged: (value) => onSortChanged(value ?? 'cercania'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<double>(
                  isExpanded: true,
                  initialValue: minRating,
                  decoration: const InputDecoration(
                    labelText: 'Calificación mín.',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0.0, child: Text('Todas')),
                    DropdownMenuItem(value: 3.0, child: Text('3+')),
                    DropdownMenuItem(value: 4.0, child: Text('4+')),
                    DropdownMenuItem(value: 4.5, child: Text('4.5+')),
                  ],
                  onChanged: (value) => onMinRatingChanged(value ?? 0.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkerListLocationHeader extends StatelessWidget {
  const WorkerListLocationHeader({
    super.key,
    required this.label,
    required this.onChangeCity,
  });

  final String label;
  final VoidCallback onChangeCity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: AppColors.brandOrangeSoft,
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.brandOrange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Profesionales en $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton(
            onPressed: onChangeCity,
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

/// Búsqueda por dirección + estado de la ubicación del cliente, en una tarjeta
/// del sistema de diseño (misma superficie, borde y radios que el resto).
class WorkerListAddressRow extends StatelessWidget {
  const WorkerListAddressRow({
    super.key,
    required this.addressController,
    required this.onSearch,
    required this.onUseGps,
    required this.locatingAddress,
    required this.locatingGps,
    required this.hasFix,
  });

  final TextEditingController addressController;
  final VoidCallback onSearch;
  final VoidCallback onUseGps;
  final bool locatingAddress;
  final bool locatingGps;
  final bool hasFix;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = AppColors.onCanvasMuted(brightness);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.surfaceCardOf(context, radius: AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: addressController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Calle, barrio o ciudad',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: locatingAddress ? null : onSearch,
                // El tema fija minimumSize en ancho infinito; dentro de un Row
                // eso colapsaba el campo de texto.
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                ),
                child: Text(locatingAddress ? '…' : 'Buscar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              WorkerListLocationChip(
                locating: locatingGps,
                ready: hasFix,
                onPressed: locatingGps ? null : onUseGps,
              ),
              Text(
                'o marca / arrastra el pin azul',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip del estado de ubicación: «Usar GPS» (acción), «Leyendo GPS…» o
/// «Ubicación lista» (verde, con check).
class WorkerListLocationChip extends StatelessWidget {
  const WorkerListLocationChip({
    super.key,
    required this.locating,
    required this.ready,
    required this.onPressed,
  });

  final bool locating;
  final bool ready;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = ready && !locating ? AppColors.success : AppColors.brandOrange;
    // En tema claro el texto va más oscuro para mantener el contraste.
    final foreground = isDark ? color : Color.alphaBlend(Colors.black38, color);
    final label = locating
        ? 'Leyendo GPS…'
        : ready
            ? 'Ubicación lista'
            : 'Usar GPS';
    return Material(
      color: color.withValues(alpha: isDark ? 0.18 : 0.12),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locating)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(
                  ready ? Icons.check_circle_rounded : Icons.my_location,
                  size: 16,
                  color: foreground,
                ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interruptor «Disponible ahora» con la misma tarjeta del sistema de diseño.
class WorkerListAvailableNowTile extends StatelessWidget {
  const WorkerListAvailableNowTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      decoration: AppDecorations.surfaceCardOf(
        context,
        radius: AppRadius.md,
        accent: value ? AppColors.success : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          secondary: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (value ? AppColors.success : AppColors.brandOrange)
                  .withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bolt_rounded,
              size: 20,
              color: value ? AppColors.success : AppColors.brandOrange,
            ),
          ),
          title: Text(
            'Disponible ahora',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onCanvas(brightness),
            ),
          ),
          subtitle: Text(
            'Respeta el horario semanal si el profesional lo activó',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onCanvasMuted(brightness),
            ),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
