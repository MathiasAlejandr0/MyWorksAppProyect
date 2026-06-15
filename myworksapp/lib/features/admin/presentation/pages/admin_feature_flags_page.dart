import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/models/feature_flag_model.dart';
import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';

class AdminFeatureFlagsPage extends ConsumerStatefulWidget {
  const AdminFeatureFlagsPage({super.key});

  @override
  ConsumerState<AdminFeatureFlagsPage> createState() =>
      _AdminFeatureFlagsPageState();
}

class _AdminFeatureFlagsPageState extends ConsumerState<AdminFeatureFlagsPage> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  List<FeatureFlagModel> _flags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listFeatureFlags();
      if (!mounted) return;
      setState(() {
        _flags = list;
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

  Future<void> _toggleFlag(FeatureFlagModel flag) async {
    final updated = flag.copyWith(
      isEnabled: !flag.isEnabled,
      updatedAt: DateTime.now(),
    );
    await _repo.upsertFeatureFlag(updated);
    await _load();
  }

  Future<void> _addFlag() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo feature flag'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre (snake_case)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (ok != true || name.isEmpty || !mounted) return;

    final now = DateTime.now();
    await _repo.upsertFeatureFlag(
      FeatureFlagModel(
        id: const Uuid().v4(),
        flagName: name,
        isEnabled: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _load();
  }

  Future<void> _deleteFlag(FeatureFlagModel flag) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar flag'),
        content: Text('¿Eliminar "${flag.flagName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _repo.deleteFeatureFlag(flag.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Feature flags'),
        actions: [
          IconButton(
            onPressed: _addFlag,
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo flag',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _flags.isEmpty
                  ? ListView(
                      padding: LayoutUtils.scrollPadding(context),
                      children: const [
                        Center(child: Text('Sin flags configurados')),
                      ],
                    )
                  : ListView.builder(
                      padding: LayoutUtils.scrollPadding(
                        context,
                        top: AppSpacing.md,
                      ),
                      itemCount: _flags.length,
                      itemBuilder: (context, index) {
                        final flag = _flags[index];
                        final scope = [
                          if (flag.role != null) 'rol: ${flag.role}',
                          if (flag.appVersion != null)
                            'v: ${flag.appVersion}',
                          if (flag.userId != null) 'usuario específico',
                        ].join(' · ');

                        return Card(
                          child: ListTile(
                            title: Text(flag.flagName),
                            subtitle: Text(
                              scope.isEmpty ? 'Global' : scope,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: flag.isEnabled,
                                  onChanged: (_) => _toggleFlag(flag),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteFlag(flag),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
