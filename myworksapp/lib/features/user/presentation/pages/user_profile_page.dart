import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';

import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/services/profile_photo_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  final JobRepository _jobRepository = JobRepository();
  bool _isLoading = false;
  bool _photoLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfilePhoto(ImageSource source) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (!mounted) return;
    setState(() => _photoLoading = true);
    try {
      final path = await ProfilePhotoService.instance.pickAndSave(
        userId: user.id,
        source: source,
        currentPath: user.profilePhotoPath,
      );
      if (path == null || !mounted) return;

      final updated = user.copyWith(profilePhotoPath: path);
      await _userRepository.updateUser(updated);
      await ref.read(authProvider.notifier).loadCurrentUser(user.id, silent: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (!mounted) return;
    setState(() => _photoLoading = true);
    try {
      await ProfilePhotoService.instance.removePhoto(user.profilePhotoPath);
      final updated = user.copyWith(clearProfilePhoto: true);
      await _userRepository.updateUser(updated);
      await ref.read(authProvider.notifier).loadCurrentUser(user.id, silent: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) return;

      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
      );

      await _userRepository.updateUser(updatedUser);
      await ref.read(authProvider.notifier).loadCurrentUser(user.id, silent: true);

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go(AppConstants.routeWelcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((s) => s.user));

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ProfileAvatarPicker(
                  displayName: user.name,
                  photoPath: user.profilePhotoPath,
                  isLoading: _photoLoading,
                  onPickFromSource: _updateProfilePhoto,
                  onRemove: _removeProfilePhoto,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca la foto para cambiarla o usar la cámara',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Información
              TextFormField(
                controller: _nameController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 24),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar cambios'),
                ),
              const SizedBox(height: 24),
              // Estadísticas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estadísticas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder(
                        future: _jobRepository.getJobsByUserId(user.id),
                        builder: (context, snapshot) {
                          final jobs = snapshot.data ?? [];
                          final completed = jobs.where((j) => j.status == AppConstants.jobStatusCompleted).length;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                icon: Icons.work,
                                label: 'Trabajos',
                                value: jobs.length.toString(),
                              ),
                              _StatItem(
                                icon: Icons.check_circle,
                                label: 'Completados',
                                value: completed.toString(),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Configuración
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push(AppConstants.routeSettings);
                },
              ),
              const Divider(),
              // Acciones
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

