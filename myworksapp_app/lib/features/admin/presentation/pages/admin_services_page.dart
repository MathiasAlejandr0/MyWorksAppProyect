import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/models/service_model.dart';
import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';

class AdminServicesPage extends ConsumerStatefulWidget {
  const AdminServicesPage({super.key});

  @override
  ConsumerState<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends ConsumerState<AdminServicesPage> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  List<ServiceModel> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.listAllServices();
      if (!mounted) return;
      setState(() {
        _services = list;
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

  Future<void> _toggleService(ServiceModel service) async {
    await _repo.setServiceActive(service.id, !service.isActive);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Catálogo de servicios')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: LayoutUtils.scrollPadding(context, top: AppSpacing.md),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final s = _services[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        s.isActive
                            ? Icons.check_circle_outline
                            : Icons.remove_circle_outline,
                        color: s.isActive
                            ? AppColors.success
                            : Colors.grey,
                      ),
                      title: Text(s.name),
                      subtitle: Text(
                        '${s.category} · ${s.pricingModel}\n'
                        '${s.description ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: Switch(
                        value: s.isActive,
                        onChanged: (_) => _toggleService(s),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
