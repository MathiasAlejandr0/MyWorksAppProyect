import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/domain/worker_custom_service.dart';
import '../../../../core/domain/worker_service_options_catalog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/service_worker_mapper.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/worker_home_refresh_provider.dart';
import '../widgets/worker_custom_services_editor.dart';
import '../widgets/worker_pricing_tiers_editor.dart';

/// Guía inicial para configurar tarifas y servicios del trabajador.
class WorkerPricingSetupPage extends ConsumerStatefulWidget {
  const WorkerPricingSetupPage({super.key, this.editMode = false});

  final bool editMode;

  @override
  ConsumerState<WorkerPricingSetupPage> createState() =>
      _WorkerPricingSetupPageState();
}

class _WorkerPricingSetupPageState extends ConsumerState<WorkerPricingSetupPage> {
  final WorkerRepository _workerRepository = WorkerRepository();
  WorkerModel? _worker;
  Map<String, int> _pricingTiers = {};
  List<WorkerCustomService> _customServices = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final worker = await _workerRepository.getWorkerByUserId(user.id);
    if (!mounted) return;

    setState(() {
      _worker = worker;
      if (worker != null) {
        _pricingTiers = worker.pricingTiers.isNotEmpty
            ? Map<String, int>.from(worker.pricingTiers)
            : WorkerServiceOptionsCatalog.defaultTiersFor(worker.serviceCategory);
        _customServices = List<WorkerCustomService>.from(worker.customServices);
      }
      _loading = false;
    });
  }

  Future<void> _saveAndContinue() async {
    final worker = _worker;
    if (worker == null) return;

    setState(() => _saving = true);
    try {
      final updated = worker.copyWith(
        pricingTiers: _pricingTiers,
        customServices: _customServices,
        pricingConfigured: true,
      );
      await _workerRepository.updateWorker(updated);

      requestWorkerHomeRefresh(ref);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarifas guardadas correctamente')),
      );
      if (widget.editMode) {
        context.pop();
      } else {
        context.go(AppConstants.routeWorkerHome);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.brandOrange)),
      );
    }

    if (_worker == null) {
      return Scaffold(
        appBar: AppGradientAppBar(title: const Text('Configurar precios')),
        body: const Center(child: Text('Primero completa tu perfil profesional')),
      );
    }

    final categoryLabel =
        ServiceWorkerMapper.labelForCategory(_worker!.serviceCategory) ??
            _worker!.profession;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: Text(widget.editMode ? 'Editar mis tarifas' : 'Configura tus precios'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.editMode) ...[
              _GuideCard(
                icon: Icons.lightbulb_outline,
                title: '¿Por qué configurar precios?',
                body:
                    'Los clientes verán estas tarifas al elegirte. Define valores claros '
                    'para cada tipo de trabajo y recibirás solicitudes más acordes a lo que ofreces.',
              ),
              const SizedBox(height: 12),
            ],
            _GuideCard(
              icon: Icons.tune,
              title: widget.editMode
                  ? 'Tarifas de $categoryLabel'
                  : 'Paso 1: Ajusta los servicios de la app',
              body:
                  'Como ${_worker!.profession}, estas opciones corresponden a trabajos de '
                  '$categoryLabel. Puedes mantener los valores sugeridos o cambiarlos.',
            ),
            const SizedBox(height: 20),
            WorkerPricingTiersEditor(
              category: _worker!.serviceCategory,
              initialTiers: _pricingTiers,
              onChanged: (tiers) => setState(() => _pricingTiers = tiers),
            ),
            const SizedBox(height: 28),
            _GuideCard(
              icon: Icons.add_circle_outline,
              title: widget.editMode
                  ? 'Servicios adicionales (opcional)'
                  : 'Paso 2: Agrega otros servicios (opcional)',
              body:
                  'Si realizas trabajos que no están en la lista de $categoryLabel, créalos aquí. '
                  'El cliente los verá debajo de un botón "Ver más".',
            ),
            const SizedBox(height: 12),
            WorkerCustomServicesEditor(
              services: _customServices,
              onChanged: (services) => setState(() => _customServices = services),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _saveAndContinue,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.editMode ? 'Guardar tarifas' : 'Guardar y continuar al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandOrange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
