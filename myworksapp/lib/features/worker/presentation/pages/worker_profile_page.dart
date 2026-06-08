import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/rating_repository.dart';
import '../../../../core/database/repositories/portfolio_repository.dart';
import '../../../../core/services/photo_service.dart';
import '../../../../core/services/profile_photo_service.dart';
import '../../../../core/widgets/portfolio_media_tile.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/models/portfolio_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/domain/worker_custom_service.dart';
import '../../../../core/domain/worker_service_options_catalog.dart';
import '../widgets/worker_custom_services_editor.dart';
import '../widgets/worker_work_zone_field.dart';
import '../widgets/worker_pricing_tiers_editor.dart';

class WorkerProfilePage extends ConsumerStatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  ConsumerState<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends ConsumerState<WorkerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _professionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  final WorkerRepository _workerRepository = WorkerRepository();
  final JobRepository _jobRepository = JobRepository();
  final RatingRepository _ratingRepository = RatingRepository();
  final PortfolioRepository _portfolioRepository = PortfolioRepository();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _photoLoading = false;
  bool _isEditing = false;
  WorkerModel? _worker;
  Map<String, int> _pricingTiers = {};
  List<WorkerCustomService> _customServices = [];
  List<PortfolioModel> _portfolio = [];
  double _averageRating = 0.0;
  String? _workZone;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _professionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final worker = await _workerRepository.getWorkerByUserId(user.id);
      final portfolio = await _portfolioRepository.getPortfolioByWorkerId(user.id);
      final avgRating = await _ratingRepository.getAverageRatingByWorkerId(user.id);

      if (!mounted) return;
      setState(() {
        _worker = worker;
        _portfolio = portfolio;
        _averageRating = avgRating;
        _nameController.text = user.name;
        _emailController.text = user.email;
        if (worker != null) {
          _professionController.text = worker.profession;
          _descriptionController.text = worker.description ?? '';
          _pricingTiers = worker.pricingTiers.isNotEmpty
              ? Map<String, int>.from(worker.pricingTiers)
              : WorkerServiceOptionsCatalog.defaultTiersFor(worker.serviceCategory);
          _customServices = List<WorkerCustomService>.from(worker.customServices);
          _workZone = worker.workZone;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
      if (mounted) await _loadData();

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
      if (mounted) await _loadData();

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

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Actualizar usuario
      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
      );
      await _userRepository.updateUser(updatedUser);

      // Actualizar trabajador
      if (_worker != null) {
        final updatedWorker = _worker!.copyWith(
          profession: _professionController.text.trim(),
          description: _descriptionController.text.trim(),
          workZone: _workZone,
          pricingTiers: _pricingTiers,
          customServices: _customServices,
          pricingConfigured: true,
        );
        await _workerRepository.updateWorker(updatedWorker);
      }

      await ref.read(authProvider.notifier).loadCurrentUser(user.id, silent: true);
      if (mounted) await _loadData();

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

  Future<void> _addPortfolioPhoto() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null) return;

      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) return;

      final savedPath = await PhotoService.instance.savePortfolioPhoto(
        File(image.path),
        user.id,
      );
      if (savedPath == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la imagen')),
        );
        return;
      }

      final portfolioItem = PortfolioModel(
        id: const Uuid().v4(),
        workerId: user.id,
        photoPath: savedPath,
        createdAt: DateTime.now(),
      );

      await _portfolioRepository.createPortfolioItem(portfolioItem);
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto agregada al portafolio')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _deletePortfolioPhoto(String id) async {
    await _portfolioRepository.deletePortfolioItem(id);
    await _loadData();
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
                  _loadData();
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileContent(context, user),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
              Center(
                child: Column(
                  children: [
                    ProfileAvatarPicker(
                      displayName: user.name,
                      photoPath: user.profilePhotoPath,
                      isLoading: _photoLoading,
                      onPickFromSource: _updateProfilePhoto,
                      onRemove: _removeProfilePhoto,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca la foto para cambiarla o usar la cámara',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Información personal
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _professionController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Profesión',
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) => Validators.validateRequired(value, 'Profesión'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Descripción profesional',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                WorkerWorkZoneField(
                  value: _workZone,
                  onChanged: (v) => setState(() => _workZone = v),
                )
              else if (_workZone != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Zona de trabajo'),
                  subtitle: Text(_workZone!),
                ),
              if (_worker != null) ...[
                const SizedBox(height: 24),
                WorkerPricingTiersEditor(
                  category: _worker!.serviceCategory,
                  initialTiers: _pricingTiers,
                  enabled: _isEditing,
                  onChanged: (tiers) => setState(() => _pricingTiers = tiers),
                ),
                const SizedBox(height: 24),
                WorkerCustomServicesEditor(
                  services: _customServices,
                  enabled: _isEditing,
                  onChanged: (services) => setState(() => _customServices = services),
                ),
              ],
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
              const SizedBox(height: 32),
              // Portafolio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Portafolio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    onPressed: _addPortfolioPhoto,
                    tooltip: 'Agregar foto',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _portfolio.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No hay fotos en el portafolio'),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: _portfolio.length,
                      itemBuilder: (context, index) {
                        final item = _portfolio[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            PortfolioMediaTile(
                              photoPath: item.photoPath,
                              mediaType: item.mediaType,
                              description: item.description,
                            ),
                            if (_isEditing)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _deletePortfolioPhoto(item.id),
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
              const SizedBox(height: 32),
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
                        future: _jobRepository.getJobsByWorkerId(user.id),
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
                              _StatItem(
                                icon: Icons.star,
                                label: 'Calificación',
                                value: _averageRating.toStringAsFixed(1),
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
              // Cerrar sesión
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
      ],
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

