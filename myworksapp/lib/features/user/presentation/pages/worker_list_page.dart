import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/domain/user_location_context.dart';
import '../../../../core/services/matching_service.dart';
import '../../../../core/services/user_location_service.dart';
import '../../../../core/services/worker_reputation_service.dart';
import '../../../../core/utils/chile_comunas.dart';
import '../../../../core/utils/platform_support.dart';
import '../../../../core/utils/worker_zone_matcher.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/app_guided_tour.dart' show AppGuidedTour, GuidedTourStep, TourTarget, TourTooltipAlign;
import '../../../../core/services/demo_tour_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkerListPage extends ConsumerStatefulWidget {
  final String? serviceId;
  final String? jobId; // Para matching automático

  const WorkerListPage({super.key, this.serviceId, this.jobId});

  @override
  ConsumerState<WorkerListPage> createState() => _WorkerListPageState();
}

class _WorkerListPageState extends ConsumerState<WorkerListPage> {
  final WorkerRepository _workerRepository = WorkerRepository();
  final UserRepository _userRepository = UserRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final MatchingService _matchingService = MatchingService.instance;
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  List<WorkerModel> _workers = [];
  List<WorkerModel> _filteredWorkers = [];
  Map<String, UserModel> _users = {};
  Map<String, double> _matchScores = {}; // Para mostrar scores en modo automático
  Set<String> _busyWorkerIds = {};
  UserLocationContext? _userLocation;
  bool _isLoading = true;
  bool _isAutomaticMode = false; // false = Manual, true = Inteligente
  String _sortBy = 'rating';
  double _minRating = 0.0;
  String? _serviceName;
  final _workerListKey = GlobalKey();
  final _firstWorkerKey = GlobalKey();

  List<GuidedTourStep> get _workersTourSteps => [
        GuidedTourStep(
          targetKey: _workerListKey,
          title: 'Profesionales disponibles',
          description:
              'Estos son los trabajadores que ofrecen este servicio. Revisa calificación, experiencia y reseñas antes de elegir.',
          align: TourTooltipAlign.above,
        ),
        GuidedTourStep(
          targetKey: _firstWorkerKey,
          title: 'Elige un profesional',
          description:
              'Toca una tarjeta para ver el perfil completo y continuar con tu solicitud de trabajo.',
          align: TourTooltipAlign.below,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Usar debounce para evitar búsquedas en cada tecla
    _debouncer.run(() {
      if (!mounted) return;
      _filterWorkers();
    });
  }

  void _filterWorkers() {
    if (!mounted) return;
    setState(() {
      _filteredWorkers = _workers.where((worker) {
        final user = _users[worker.userId];
        final matchesSearch = _searchController.text.isEmpty ||
            user?.name.toLowerCase().contains(_searchController.text.toLowerCase()) == true ||
            worker.profession.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesRating = worker.rating >= _minRating;
        return matchesSearch && matchesRating;
      }).toList();

      if (_sortBy == 'rating') {
        WorkerReputationService.instance.sortForListing(_filteredWorkers);
      } else {
        _filteredWorkers.sort((a, b) {
          final nameA = _users[a.userId]?.name ?? '';
          final nameB = _users[b.userId]?.name ?? '';
          return nameA.compareTo(nameB);
        });
      }
    });
  }

  Future<void> _resolveUserLocation() async {
    if (widget.jobId != null) {
      final job = await JobRepository().getJobById(widget.jobId!);
      if (job?.latitude != null && job?.longitude != null) {
        _userLocation = await UserLocationService.instance.fromCoordinates(
          job!.latitude!,
          job.longitude!,
        );
        if (_userLocation != null) {
          await UserLocationService.instance.persist(_userLocation!);
          return;
        }
      }
    }
    _userLocation = await UserLocationService.instance.resolve();
  }

  Future<void> _selectCityManually() async {
    String? selected = 'Puerto Montt';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Selecciona tu ciudad'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: 'Ciudad',
              prefixIcon: Icon(Icons.location_city),
            ),
            items: ChileComunas.allZones
                .where((z) => !z.contains('(todas)'))
                .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                .toList(),
            onChanged: (v) => setDialogState(() => selected = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Usar esta ciudad'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || selected == null || !mounted) return;

    _userLocation = await UserLocationService.instance.setManualCity(selected!);
    await _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _resolveUserLocation();
      if (_isAutomaticMode && widget.jobId != null && widget.serviceId != null) {
        // Modo automático: usar MatchingService
        await _loadAutomaticMatching();
      } else {
        // Modo manual: lógica existente
        await _loadManualWorkers();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _loadAutomaticMatching() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      
      if (user == null || widget.jobId == null || widget.serviceId == null) {
        await _loadManualWorkers();
        return;
      }

      // Obtener job para obtener coordenadas
      final JobRepository _jobRepository = JobRepository();
      final job = await _jobRepository.getJobById(widget.jobId!);
      
      if (job == null || job.latitude == null || job.longitude == null) {
        // Si no hay coordenadas, usar modo manual
        await _loadManualWorkers();
        return;
      }

      // Usar coordenadas del job para matching
      final matches = await _matchingService.automaticMatching(
        jobId: widget.jobId!,
        serviceId: widget.serviceId!,
        userLatitude: job.latitude!,
        userLongitude: job.longitude!,
        maxResults: 5,
      );

      // Convertir MatchResult a WorkerModel y guardar scores
      final workers = <WorkerModel>[];
      final users = <String, UserModel>{};
      final scores = <String, double>{};

      for (final match in matches) {
        if (_userLocation == null) break;
        if (!WorkerZoneMatcher.serves(
          workZone: match.worker.workZone,
          userLocation: _userLocation!,
        )) {
          continue;
        }
        workers.add(match.worker);
        users[match.worker.userId] = match.user;
        scores[match.worker.userId] = match.score;
      }

      if (!mounted) return;
      setState(() {
        _workers = workers;
        _filteredWorkers = workers;
        _users = users;
        _matchScores = scores;
        _isLoading = false;
      });
    } catch (e) {
      // Si falla matching automático, cargar manual
      await _loadManualWorkers();
    }
  }

  Future<void> _loadManualWorkers() async {
    List<WorkerModel> workers;

    if (widget.serviceId != null) {
      final service = await _serviceRepository.getServiceById(widget.serviceId!);
      _serviceName = service?.name;

      if (service != null) {
        workers = await _workerRepository.getWorkersByServiceCategory(
          service.category,
          near: _userLocation,
        );
      } else {
        workers = await _workerRepository.getAvailableWorkersWithoutActiveJobs(
          near: _userLocation,
        );
      }
    } else {
      workers = await _workerRepository.getAvailableWorkersWithoutActiveJobs(
        near: _userLocation,
      );
    }

    final busyIds = <String>{};
    for (final worker in workers) {
      if (await _workerRepository.hasActiveJobs(worker.userId)) {
        busyIds.add(worker.userId);
      }
    }
    _busyWorkerIds = busyIds;

    // Cargar información de usuarios
    final users = <String, UserModel>{};
    for (var worker in workers) {
      final user = await _userRepository.getUserById(worker.userId);
      if (user != null) {
        users[worker.userId] = user;
      }
    }

    if (!mounted) return;
    setState(() {
      _workers = workers;
      _users = users;
      _matchScores = {};
      _isLoading = false;
    });
    _filterWorkers();
  }

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: AppDecorations.screenBackground,
      appBar: AppGradientAppBar(
        title: Text(_serviceName ?? 'Trabajadores disponibles'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _workers.isEmpty
              ? _userLocation == null
                  ? _LocationRequiredState(
                      onRetry: _loadWorkers,
                      onSelectCity: _selectCityManually,
                      isDesktop: AppPlatform.isDesktopNative,
                    )
                  : EmptyStateWidget(
                      icon: Icons.person_off,
                      title: 'No hay trabajadores en tu ciudad',
                      message:
                          'Solo mostramos profesionales en ${_userLocation!.city}. No hay disponibles para este servicio aquí.',
                      actionLabel: 'Ver otros servicios',
                      onAction: () => context.go(AppConstants.routeUserHome),
                    )
              : Column(
                  children: [
                    if (_userLocation != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        color: AppColors.brandOrangeSoft,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.brandOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Profesionales en ${_userLocation!.displayLabel}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Toggle Modo Manual / Inteligente
                    if (widget.jobId != null && widget.serviceId != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.grayLight,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Modo de búsqueda',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            CupertinoSlidingSegmentedControl<bool>(
                              groupValue: _isAutomaticMode,
                              children: const {
                                false: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text('Lista Manual'),
                                ),
                                true: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text('Búsqueda Inteligente'),
                                ),
                              },
                              onValueChanged: (value) {
                                setState(() {
                                  _isAutomaticMode = value ?? false;
                                });
                                _loadWorkers();
                              },
                            ),
                          ],
                        ),
                      ),
                    // Búsqueda y filtros (solo en modo manual)
                    if (!_isAutomaticMode)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre o profesión...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _sortBy,
                                  decoration: const InputDecoration(
                                    labelText: 'Ordenar por',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'rating', child: Text('Calificación')),
                                    DropdownMenuItem(value: 'name', child: Text('Nombre')),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _sortBy = value ?? 'rating');
                                    _filterWorkers();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<double>(
                                  initialValue: _minRating,
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
                                  onChanged: (value) {
                                    setState(() => _minRating = value ?? 0.0);
                                    _filterWorkers();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Lista
                    Expanded(
                      child: _filteredWorkers.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.search_off,
                              title: 'No se encontraron trabajadores',
                              message: 'Intenta con otros filtros o busca otro servicio',
                            )
                          : TourTarget(
                              tourKey: _workerListKey,
                              width: double.infinity,
                              child: RefreshIndicator(
                                onRefresh: _loadWorkers,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredWorkers.length,
                                  itemBuilder: (context, index) {
                                    final worker = _filteredWorkers[index];
                                    final user = _users[worker.userId];
                                    final score = _matchScores[worker.userId];
                                    final card = _WorkerCard(
                                      worker: worker,
                                      user: user,
                                      isBusy: _busyWorkerIds.contains(worker.userId),
                                      isRecommended: _isAutomaticMode && score != null,
                                      matchScore: score,
                                      onTap: () {
                                        context.push(
                                          '${AppConstants.routeWorkerDetail}/${worker.userId}',
                                          extra: {'serviceId': widget.serviceId},
                                        );
                                      },
                                    );
                                    if (index == 0) {
                                      return TourTarget(
                                        tourKey: _firstWorkerKey,
                                        width: double.infinity,
                                        child: card,
                                      );
                                    }
                                    return card;
                                  },
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );

    if (_isLoading || _filteredWorkers.isEmpty) return page;

    return AppGuidedTour(
      steps: _workersTourSteps,
      shouldShow: DemoTourService.shouldShowWorkersTour,
      onComplete: DemoTourService.completeWorkersTour,
      child: page,
    );
  }
}

class _LocationRequiredState extends StatelessWidget {
  const _LocationRequiredState({
    required this.onRetry,
    required this.onSelectCity,
    required this.isDesktop,
  });

  final VoidCallback onRetry;
  final VoidCallback onSelectCity;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: AppColors.brandOrange),
            const SizedBox(height: 24),
            Text(
              'Ubicación requerida',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isDesktop
                  ? 'En Windows el GPS a veces no responde. Reintenta o selecciona tu ciudad manualmente.'
                  : 'Activa el GPS y permite ubicación para ver profesionales solo de tu ciudad.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grayMedium,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 280,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 280,
              child: OutlinedButton.icon(
                onPressed: onSelectCity,
                icon: const Icon(Icons.location_city),
                label: const Text('Seleccionar mi ciudad'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final UserModel? user;
  final bool isBusy;
  final bool isRecommended;
  final double? matchScore;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.worker,
    this.user,
    this.isBusy = false,
    this.isRecommended = false,
    this.matchScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecorations.surfaceCard(accent: AppColors.primaryLight),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ProfileAvatarView(
                  displayName: user?.name ?? 'Trabajador',
                  photoPath: user?.profilePhotoPath,
                  radius: 26,
                  onDarkBackground: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecommended)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Recomendado${matchScore != null ? ' ${(matchScore! * 100).toStringAsFixed(0)}%' : ''}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      Text(
                        user?.name ?? 'Trabajador',
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        worker.profession,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grayMedium,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _ChipBadge(
                            icon: Icons.star_rounded,
                            label: worker.rating.toStringAsFixed(1),
                            color: AppColors.warning,
                          ),
                          if (worker.workZone != null)
                            _ChipBadge(
                              icon: Icons.location_on_outlined,
                              label: worker.workZone!,
                              color: AppColors.grayMedium,
                            ),
                          if (isBusy)
                            _ChipBadge(
                              icon: Icons.schedule,
                              label: 'Ocupado',
                              color: AppColors.brandOrange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.grayMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  const _ChipBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

