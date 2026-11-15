import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
                child: DropdownButtonFormField<String>(
                  initialValue: sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Ordenar por',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rating', child: Text('Calificación')),
                    DropdownMenuItem(value: 'name', child: Text('Nombre')),
                  ],
                  onChanged: (value) => onSortChanged(value ?? 'rating'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<double>(
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
              const SizedBox(width: 8),
              FilledButton(
                onPressed: locatingAddress ? null : onSearch,
                child: Text(locatingAddress ? '…' : 'Buscar'),
              ),
            ],
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: locatingGps ? null : onUseGps,
                icon: locatingGps
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(
                  locatingGps
                      ? 'Leyendo GPS…'
                      : hasFix
                          ? 'Ubicación lista'
                          : 'Usar GPS',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'o marca / arrastra el pin azul',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
