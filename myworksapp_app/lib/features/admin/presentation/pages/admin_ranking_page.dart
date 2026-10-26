import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/models/ranking_models.dart';
import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';

class AdminRankingPage extends ConsumerStatefulWidget {
  const AdminRankingPage({super.key});

  @override
  ConsumerState<AdminRankingPage> createState() => _AdminRankingPageState();
}

class _AdminRankingPageState extends ConsumerState<AdminRankingPage>
    with SingleTickerProviderStateMixin {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  late final TabController _tabs;
  RankingConfig _config = const RankingConfig();
  List<ReviewSignal> _signals = [];
  String _signalFilter = 'pendiente';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await _repo.fetchRankingConfig();
      final signals = await _repo.listReviewSignals(status: _signalFilter);
      if (!mounted) return;
      setState(() {
        _config = config;
        _signals = signals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await _repo.saveRankingConfig(_config);
      if (!mounted) return;
      setState(() {
        _config = saved;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesos guardados. El listado se recalculó.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _learn() async {
    setState(() => _saving = true);
    try {
      final result = await _repo.learnRankingWeights();
      await _load();
      if (!mounted) return;
      setState(() => _saving = false);
      final ok = result['ok'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'El ranking aprendió de ${result['positivos']} trabajos bien cerrados y ${result['negativos']} fallidos.'
                : 'Aún no hay muestra suficiente (${result['motivo'] ?? 'sin datos'}).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resolve(ReviewSignal signal, String status) async {
    try {
      await _repo.resolveReviewSignal(signal.id, status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Ranking y reseñas'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pesos del listado'),
            Tab(text: 'Reseñas dudosas'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _WeightsTab(
                  config: _config,
                  saving: _saving,
                  onChanged: (next) => setState(() => _config = next),
                  onSave: _save,
                  onLearn: _learn,
                ),
                _SignalsTab(
                  signals: _signals,
                  filter: _signalFilter,
                  onFilter: (value) {
                    _signalFilter = value;
                    _load();
                  },
                  onResolve: _resolve,
                ),
              ],
            ),
    );
  }
}

class _WeightsTab extends StatelessWidget {
  const _WeightsTab({
    required this.config,
    required this.saving,
    required this.onChanged,
    required this.onSave,
    required this.onLearn,
  });

  final RankingConfig config;
  final bool saving;
  final ValueChanged<RankingConfig> onChanged;
  final VoidCallback onSave;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: LayoutUtils.scrollPadding(context),
      children: [
        Text(
          'Quién aparece primero',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Estos pesos ordenan el marketplace. Sube un factor para que ese criterio mande. '
          'La prioridad manual de cada trabajador (en Trabajadores) se suma encima.',
        ),
        const SizedBox(height: AppSpacing.md),
        _WeightSlider(
          label: 'Calificación Bayesiana',
          value: config.pesoCalificacion,
          onChanged: (v) => onChanged(config.copyWith(pesoCalificacion: v)),
        ),
        _WeightSlider(
          label: 'Trabajos completados',
          value: config.pesoCompletados,
          onChanged: (v) => onChanged(config.copyWith(pesoCompletados: v)),
        ),
        _WeightSlider(
          label: 'Pocos rechazos',
          value: config.pesoRechazos,
          onChanged: (v) => onChanged(config.copyWith(pesoRechazos: v)),
        ),
        _WeightSlider(
          label: 'Verificación',
          value: config.pesoVerificacion,
          onChanged: (v) => onChanged(config.copyWith(pesoVerificacion: v)),
        ),
        _WeightSlider(
          label: 'Impulso activo',
          value: config.pesoImpulso,
          onChanged: (v) => onChanged(config.copyWith(pesoImpulso: v)),
        ),
        _WeightSlider(
          label: 'Actividad reciente',
          value: config.pesoRecencia,
          onChanged: (v) => onChanged(config.copyWith(pesoRecencia: v)),
        ),
        _WeightSlider(
          label: 'Confianza de reseñas',
          value: config.pesoConfianza,
          onChanged: (v) => onChanged(config.copyWith(pesoConfianza: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Aprendizaje automático'),
          subtitle: const Text(
            'Ajusta los pesos cuando hay trabajos bien cerrados o disputas.',
          ),
          value: config.aprendizajeActivo,
          onChanged: (v) => onChanged(config.copyWith(aprendizajeActivo: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Guardando…' : 'Guardar y recalcular'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onLearn,
                child: const Text('Aprender ahora'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${(value * 100).round()}%'),
            ],
          ),
          Slider(
            value: value.clamp(0.03, 0.50),
            min: 0.03,
            max: 0.50,
            divisions: 47,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SignalsTab extends StatelessWidget {
  const _SignalsTab({
    required this.signals,
    required this.filter,
    required this.onFilter,
    required this.onResolve,
  });

  final List<ReviewSignal> signals;
  final String filter;
  final ValueChanged<String> onFilter;
  final void Function(ReviewSignal, String) onResolve;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Pendientes'),
                selected: filter == 'pendiente',
                onSelected: (_) => onFilter('pendiente'),
              ),
              FilterChip(
                label: const Text('Fraude'),
                selected: filter == 'fraude_confirmado',
                onSelected: (_) => onFilter('fraude_confirmado'),
              ),
              FilterChip(
                label: const Text('Falsos positivos'),
                selected: filter == 'falso_positivo',
                onSelected: (_) => onFilter('falso_positivo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: signals.isEmpty
              ? const Center(child: Text('No hay reseñas en esta cola'))
              : ListView.builder(
                  padding: LayoutUtils.scrollPadding(context, top: AppSpacing.sm),
                  itemCount: signals.length,
                  itemBuilder: (context, index) {
                    final s = signals[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${s.signalLabel} · ★ ${s.reviewScore ?? '-'}',
                        ),
                        subtitle: Text(
                          '${s.clientName ?? 'Cliente'} → ${s.workerName ?? 'Trabajador'}\n'
                          '${s.detail ?? ''}'
                          '${s.comment == null || s.comment!.isEmpty ? '' : '\n"${s.comment}"'}',
                        ),
                        isThreeLine: true,
                        trailing: filter == 'pendiente'
                            ? PopupMenuButton<String>(
                                onSelected: (v) => onResolve(s, v),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'falso_positivo',
                                    child: Text('Es falsa alarma'),
                                  ),
                                  PopupMenuItem(
                                    value: 'fraude_confirmado',
                                    child: Text('Confirmar fraude'),
                                  ),
                                  PopupMenuItem(
                                    value: 'descartada',
                                    child: Text('Descartar'),
                                  ),
                                ],
                              )
                            : Text(
                                s.status,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
