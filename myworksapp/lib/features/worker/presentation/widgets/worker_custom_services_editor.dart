import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/domain/worker_custom_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Editor de servicios adicionales del trabajador.
class WorkerCustomServicesEditor extends StatelessWidget {
  const WorkerCustomServicesEditor({
    super.key,
    required this.services,
    required this.onChanged,
    this.enabled = true,
  });

  final List<WorkerCustomService> services;
  final ValueChanged<List<WorkerCustomService>> onChanged;
  final bool enabled;

  Future<void> _openAddDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final priceController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar servicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del servicio',
                  hintText: 'Ej: Instalación de cortinas',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Descripción breve',
                  hintText: 'Ej: Hasta 3 ventanas estándar',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  suffixText: 'CLP',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (added != true) {
      titleController.dispose();
      subtitleController.dispose();
      priceController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final subtitle = subtitleController.text.trim();
    final price = int.tryParse(priceController.text.trim()) ?? 0;

    titleController.dispose();
    subtitleController.dispose();
    priceController.dispose();

    if (title.isEmpty || price <= 0) return;

    onChanged([
      ...services,
      WorkerCustomService.create(
        title: title,
        subtitle: subtitle.isEmpty ? 'Servicio personalizado' : subtitle,
        priceClp: price,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Servicios adicionales',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (enabled)
              TextButton.icon(
                onPressed: () => _openAddDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Opcional. Aparecerán bajo "Ver más" cuando un cliente elija tu perfil.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.grayMedium,
              ),
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grayMedium.withValues(alpha: 0.2)),
            ),
            child: Text(
              'Aún no agregaste servicios personalizados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...services.map((service) {
            final option = service.toOptionDef();
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.grayMedium.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: Icon(option.icon, color: AppColors.brandNavy),
                title: Text(service.title),
                subtitle: Text(service.subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.priceLabel(service.priceClp),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandOrange,
                          ),
                    ),
                    if (enabled) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red.shade400,
                        onPressed: () {
                          onChanged(
                            services.where((s) => s.id != service.id).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
