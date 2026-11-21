import 'package:myworksapp/core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'dart:io';

import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/domain/worker_public_stats.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
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
import '../widgets/worker_verification_card.dart';
import '../../../user/presentation/widgets/testing_feedback_sheet.dart';
import '../widgets/worker_base_location_card.dart';
import '../widgets/worker_urban_coverage_card.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../widgets/sii_tax_info_widget.dart';
import '../widgets/worker_custom_services_editor.dart';
import '../widgets/worker_profile_section_card.dart';
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
  final PortfolioRepository _portfolioRepository = PortfolioRepository();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String? _loadError;
  bool _photoLoading = false;
  String? _editingSection;
  WorkerModel? _worker;
  Map<String, int> _pricingTiers = {};
  List<WorkerCustomService> _customServices = [];
  List<PortfolioModel> _portfolio = [];
  double _averageRating = 0.0;
  String? _workZone;
  int _jobsCount = 0;
  int _completedJobsCount = 0;

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

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final worker = await _workerRepository.getWorkerByUserId(user.id);
      var portfolio = <PortfolioModel>[];
      try {
        portfolio = await _portfolioRepository.getPortfolioByWorkerId(user.id);
      } catch (_) {}
      WorkerPublicStats? stats;
      try {
        stats = await _workerRepository.getPublicStats(user.id);
      } catch (_) {}
      var jobsTotal = 0;
      try {
        jobsTotal =
            (await _jobRepository.countJobsByWorkerId(user.id)).total;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _worker = worker;
        _portfolio = portfolio;
        _averageRating = stats?.averageRating ?? 0;
        _jobsCount = jobsTotal;
        _completedJobsCount = stats?.completedJobs ?? 0;
        _nameController.text = user.name;
        _emailController.text = user.email;
        if (worker != null) {
          _professionController.text = worker.profession;
          _descriptionController.text = worker.description ?? '';
          _pricingTiers = worker.pricingTiers.isNotEmpty
              ? Map<String, int>.from(worker.pricingTiers)
              : WorkerServiceOptionsCatalog.defaultTiersFor(
                  worker.serviceCategory,
                );
          _customServices = List<WorkerCustomService>.from(
            worker.customServices,
          );
          _workZone = worker.workZone;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = ErrorHandler.userMessage(
          e,
          fallback: 'No se pudo cargar el perfil. Inténtalo de nuevo.',
        );
      });
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
      await ref
          .read(authProvider.notifier)
          .loadCurrentUser(user.id, silent: true);
      if (mounted) await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.userMessage(
              e,
              fallback: 'No se pudo actualizar la foto.',
            ),
          ),
        ),
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
      await ref
          .read(authProvider.notifier)
          .loadCurrentUser(user.id, silent: true);
      if (mounted) await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto de perfil eliminada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ErrorHandler.userMessage(e))));
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

      // Actualizar trabajador. Las tarifas de catálogo solo viven en memoria
      // para el editor: guardar el nombre no las publica.
      if (_worker != null) {
        final editingPrices = _editingSection == 'tarifas';
        final editingExtras = _editingSection == 'servicios';
        final updatedWorker = _worker!.copyWith(
          profession: _professionController.text.trim(),
          description: _descriptionController.text.trim(),
          workZone: _workZone,
          pricingTiers: editingPrices ? _pricingTiers : _worker!.pricingTiers,
          customServices:
              editingExtras ? _customServices : _worker!.customServices,
          pricingConfigured: editingPrices ? true : null,
        );
        await _workerRepository.updateWorker(
          updatedWorker,
          savePrices: editingPrices,
          saveExtras: editingExtras,
        );
      }

      await ref
          .read(authProvider.notifier)
          .loadCurrentUser(user.id, silent: true);
      if (mounted) await _loadData();

      if (!mounted) return;
      setState(() {
        _editingSection = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ErrorHandler.userMessage(e))));
    }
  }

  void _restoreDraft() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
    final worker = _worker;
    if (worker != null) {
      _professionController.text = worker.profession;
      _descriptionController.text = worker.description ?? '';
      _workZone = worker.workZone;
      _pricingTiers = worker.pricingTiers.isNotEmpty
          ? Map<String, int>.from(worker.pricingTiers)
          : WorkerServiceOptionsCatalog.defaultTiersFor(worker.serviceCategory);
      _customServices = List<WorkerCustomService>.from(worker.customServices);
    }
  }

  void _beginEdit(String section) {
    if (_editingSection == section) return;
    _restoreDraft();
    setState(() => _editingSection = section);
  }

  void _cancelEdit() {
    _restoreDraft();
    setState(() => _editingSection = null);
  }

  String _shortText(String value, String empty) {
    final text = value.trim();
    if (text.isEmpty) return empty;
    if (text.length <= 90) return text;
    return '${text.substring(0, 90)}…';
  }

  List<String> _pricingSummary() {
    final worker = _worker;
    if (worker == null) return const ['Sin tarifas'];
    final options =
        WorkerServiceOptionsCatalog.pricingOptionsFor(worker.serviceCategory);
    if (options.isEmpty) return const ['Sin tarifas para este oficio'];
    return options.take(3).map((option) {
      final price = WorkerServiceOptionsCatalog.priceFor(
        workerTiers: _pricingTiers,
        option: option,
      );
      return '${option.title} · ${option.priceLabel(price)}';
    }).toList();
  }

  Widget _portfolioBody() {
    final editing = _editingSection == 'portafolio';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addPortfolioPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Agregar foto'),
          ),
        ),
        if (_portfolio.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Todavía no hay fotos. Agrega trabajos que quieras mostrar.'),
          )
        else
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _portfolio.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _portfolio[index];
                return SizedBox(
                  width: 84,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PortfolioMediaTile(
                        photoPath: item.photoPath,
                        mediaType: item.mediaType,
                        description: item.description,
                        showDescription: false,
                        compact: true,
                      ),
                      if (editing)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.error,
                                size: 18,
                              ),
                              onPressed: () => _deletePortfolioPhoto(item.id),
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ErrorHandler.userMessage(e))));
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
      return const Scaffold(body: Center(child: Text('Usuario no encontrado')));
    }

    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Mi Perfil')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: LayoutUtils.scrollPadding(context),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_buildProfileContent(context, user)],
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
        _ProfileIdentityCard(
          name: user.name,
          photoPath: user.profilePhotoPath,
          photoLoading: _photoLoading,
          ratingLabel: WorkerPublicStats.ratingLabel(_averageRating),
          jobsCount: _jobsCount,
          completedCount: _completedJobsCount,
          onPickFromSource: _updateProfilePhoto,
          onRemovePhoto: _removeProfilePhoto,
        ),
        const SizedBox(height: 8),
        Text(
          'Cada bloque se edita por separado.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onCanvasMuted(Theme.of(context).brightness),
              ),
        ),
        const SizedBox(height: 14),
        if (_loadError != null)
          ErrorStateWidget(
            title: 'Perfil no disponible',
            message: _loadError!,
            actionLabel: 'Reintentar',
            onRetry: _loadData,
          )
        else if (_worker == null && !_isLoading)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aún no tienes ficha de especialista.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        context.push(AppConstants.routeWorkerRegister),
                    child: const Text('Completar registro'),
                  ),
                ],
              ),
            ),
          ),
        WorkerVerificationCard(userId: user.id),
        if (_worker != null)
          WorkerBaseLocationCard(
            latitude: _worker!.baseLatitude,
            longitude: _worker!.baseLongitude,
            radiusKm: _worker!.serviceRadiusKm,
            origin: _worker!.baseOrigin,
            enabled: true,
            onSave: (latitude, longitude, radiusKm) async {
              await _workerRepository.updateBaseLocation(
                userId: user.id,
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm,
              );
              await _loadData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ubicación base guardada')),
              );
            },
          ),
        if (_worker != null)
          WorkerUrbanCoverageCard(
            urbanRadiusKm: _worker!.urbanRadiusKm,
            outsideFeeClp: _worker!.outsideMobilizationFeeClp,
            enabled: true,
            onSave: (urbanRadiusKm, outsideFeeClp) async {
              await _workerRepository.updateUrbanCoverage(
                userId: user.id,
                urbanRadiusKm: urbanRadiusKm,
                outsideFeeClp: outsideFeeClp,
              );
              await _loadData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Radio urbano guardado')),
              );
            },
          ),
        const SizedBox(height: 16),
        WorkerProfileSectionCard(
          icon: Icons.person_outline,
          title: 'Datos personales',
          summary: [
            _shortText(_nameController.text, 'Sin nombre'),
            _shortText(_emailController.text, 'Sin correo'),
          ],
          editing: _editingSection == 'personal',
          saving: _isLoading && _editingSection == 'personal',
          onEdit: () => _beginEdit('personal'),
          onCancel: _cancelEdit,
          onSave: _saveChanges,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: Validators.validateEmail,
              ),
            ],
          ),
        ),
        WorkerProfileSectionCard(
          icon: Icons.work_outline,
          title: 'Oficio',
          summary: [
            _shortText(_professionController.text, 'Sin profesión'),
            _shortText(_descriptionController.text, 'Sin descripción'),
            _workZone ?? 'Sin zona de trabajo',
          ],
          editing: _editingSection == 'oficio',
          saving: _isLoading && _editingSection == 'oficio',
          onEdit: () => _beginEdit('oficio'),
          onCancel: _cancelEdit,
          onSave: _saveChanges,
          child: Column(
            children: [
              TextFormField(
                controller: _professionController,
                decoration: const InputDecoration(
                  labelText: 'Profesión',
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) =>
                    Validators.validateRequired(value, 'Profesión'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción profesional',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
                validator: (value) {
                  if ((value ?? '').trim().length > 500) {
                    return 'La descripción no puede superar 500 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              WorkerWorkZoneField(
                value: _workZone,
                onChanged: (value) => setState(() => _workZone = value),
              ),
            ],
          ),
        ),
        if (_worker != null)
          WorkerProfileSectionCard(
            icon: Icons.payments_outlined,
            title: 'Tarifas',
            summary: _pricingSummary(),
            editing: _editingSection == 'tarifas',
            saving: _isLoading && _editingSection == 'tarifas',
            onEdit: () => _beginEdit('tarifas'),
            onCancel: _cancelEdit,
            onSave: _saveChanges,
            child: WorkerPricingTiersEditor(
              category: _worker!.serviceCategory,
              initialTiers: _pricingTiers,
              onChanged: (tiers) => setState(() => _pricingTiers = tiers),
            ),
          ),
        if (_worker != null)
          WorkerProfileSectionCard(
            icon: Icons.handyman_outlined,
            title: 'Servicios adicionales',
            summary: _customServices.isEmpty
                ? const ['Sin servicios adicionales']
                : _customServices.take(3).map((service) => service.title).toList(),
            editing: _editingSection == 'servicios',
            saving: _isLoading && _editingSection == 'servicios',
            onEdit: () => _beginEdit('servicios'),
            onCancel: _cancelEdit,
            onSave: _saveChanges,
            child: WorkerCustomServicesEditor(
              services: _customServices,
              onChanged: (services) =>
                  setState(() => _customServices = services),
            ),
          ),
        WorkerProfileSectionCard(
          icon: Icons.photo_library_outlined,
          title: 'Portafolio',
          summary: [
            _portfolio.isEmpty
                ? 'Sin fotos todavía'
                : '${_portfolio.length} ${_portfolio.length == 1 ? 'foto' : 'fotos'}',
          ],
          editing: _editingSection == 'portafolio',
          alwaysShowBody: true,
          saveLabel: 'Listo',
          onEdit: () => _beginEdit('portafolio'),
          onCancel: () => setState(() => _editingSection = null),
          onSave: () => setState(() => _editingSection = null),
          child: _portfolioBody(),
        ),
        const SiiTaxInfoWidget(),
        const SizedBox(height: 8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: AppDecorations.surfaceCardOf(
            context,
            accent: AppColors.brandOrange,
          ),
          child: Column(
            children: [
              const ColoredBox(
                color: _profileHeader,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Cuenta',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: AppColors.brandOrange),
                title: const Text('Configuración'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push(AppConstants.routeSettings);
                },
              ),
              ListTile(
                leading: const Icon(Icons.rate_review_outlined, color: AppColors.brandOrange),
                title: const Text('Encuesta de la prueba'),
                subtitle: const Text('Cuéntanos cómo te fue usando MyWorksApp'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => TestingFeedbackSheet.show(context, role: 'profesional'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _profileHeader = Color(0xFF2B3038);

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.name,
    required this.photoPath,
    required this.photoLoading,
    required this.ratingLabel,
    required this.jobsCount,
    required this.completedCount,
    required this.onPickFromSource,
    required this.onRemovePhoto,
  });

  final String name;
  final String? photoPath;
  final bool photoLoading;
  final String ratingLabel;
  final int jobsCount;
  final int completedCount;
  final Future<void> Function(ImageSource source) onPickFromSource;
  final Future<void> Function() onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.surfaceCardOf(
        context,
        accent: AppColors.brandOrange,
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          ProfileAvatarPicker(
            displayName: name,
            photoPath: photoPath,
            isLoading: photoLoading,
            onPickFromSource: onPickFromSource,
            onRemove: onRemovePhoto,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toca la foto para cambiarla',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 14),
          ColoredBox(
            color: _profileHeader,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _IdentityStat(value: '$jobsCount', label: 'Trabajos'),
                  _IdentityStat(value: '$completedCount', label: 'Completados'),
                  _IdentityStat(value: ratingLabel, label: 'Calificación'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityStat extends StatelessWidget {
  const _IdentityStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.brandOrange, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
