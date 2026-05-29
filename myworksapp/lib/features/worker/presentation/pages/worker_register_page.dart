import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WorkerRegisterPage extends ConsumerStatefulWidget {
  const WorkerRegisterPage({super.key});

  @override
  ConsumerState<WorkerRegisterPage> createState() => _WorkerRegisterPageState();
}

class _WorkerRegisterPageState extends ConsumerState<WorkerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _professionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final WorkerRepository _workerRepository = WorkerRepository();
  bool _isLoading = false;

  final List<String> _professions = [
    'Maestro Constructor',
    'Gasfiter',
    'Electricista',
    'Cerrajero',
    'Pintor',
    'Técnico en General',
  ];

  String? _selectedProfession;

  @override
  void dispose() {
    _professionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProfession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una profesión')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión')),
        );
        return;
      }

      final worker = WorkerModel(
        userId: user.id,
        profession: _selectedProfession!,
        description: _descriptionController.text.trim(),
        isAvailable: true,
      );

      await _workerRepository.createWorker(worker);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil creado exitosamente')),
      );

      context.go(AppConstants.routeWorkerHome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Completa tu perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Información profesional',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Completa tu perfil para comenzar a recibir solicitudes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                initialValue: _selectedProfession,
                decoration: const InputDecoration(
                  labelText: 'Profesión',
                  prefixIcon: Icon(Icons.work),
                ),
                items: _professions.map((profession) {
                  return DropdownMenuItem(
                    value: profession,
                    child: Text(profession),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProfession = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona una profesión';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción profesional',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Describe tus habilidades y experiencia',
                ),
                maxLines: 5,
                validator: Validators.validateDescription,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Completar perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

