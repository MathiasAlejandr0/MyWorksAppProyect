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
import '../../../../core/services/matching_service.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/models/service_model.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/error_handler.dart';
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
  final _currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  List<WorkerModel> _workers = [];
  List<WorkerModel> _filteredWorkers = [];
  Map<String, UserModel> _users = {};
  Map<String, double> _matchScores = {}; // Para mostrar scores en modo automático
  bool _isLoading = true;
  bool _isAutomaticMode = false; // false = Manual, true = Inteligente
  String _sortBy = 'rating';
  double _minRating = 0.0;
  String? _serviceName;

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
      _filterWorkers();
    });
  }

  void _filterWorkers() {
    setState(() {
      _filteredWorkers = _workers.where((worker) {
        final user = _users[worker.userId];
        final matchesSearch = _searchController.text.isEmpty ||
            user?.name.toLowerCase().contains(_searchController.text.toLowerCase()) == true ||
            worker.profession.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesRating = worker.rating >= _minRating;
        return matchesSearch && matchesRating;
      }).toList();

      // Ordenar
      _filteredWorkers.sort((a, b) {
        if (_sortBy == 'rating') {
          return b.rating.compareTo(a.rating);
        } else {
          final nameA = _users[a.userId]?.name ?? '';
          final nameB = _users[b.userId]?.name ?? '';
          return nameA.compareTo(nameB);
        }
      });
    });
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);

    try {
      if (_isAutomaticMode && widget.jobId != null && widget.serviceId != null) {
        // Modo automático: usar MatchingService
        await _loadAutomaticMatching();
      } else {
        // Modo manual: lógica existente
        await _loadManualWorkers();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
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
        workers.add(match.worker);
        users[match.worker.userId] = match.user;
        scores[match.worker.userId] = match.score;
      }

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
        workers = await _workerRepository.getWorkersByServiceCategory(service.category);
      } else {
        workers = await _workerRepository.getAvailableWorkersWithoutActiveJobs();
      }
    } else {
      workers = await _workerRepository.getAvailableWorkersWithoutActiveJobs();
    }

    final jobRepository = JobRepository();
    final available = <WorkerModel>[];
    for (final worker in workers) {
      if (worker.isAvailable && !await jobRepository.hasActiveJobs(worker.userId)) {
        available.add(worker);
      }
    }
    workers = available;

    // Cargar información de usuarios
    final users = <String, UserModel>{};
    for (var worker in workers) {
      final user = await _userRepository.getUserById(worker.userId);
      if (user != null) {
        users[worker.userId] = user;
      }
    }

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
    return Scaffold(
      backgroundColor: AppDecorations.screenBackground,
      appBar: AppGradientAppBar(
        title: Text(_serviceName ?? 'Trabajadores disponibles'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _workers.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.person_off,
                  title: 'No hay trabajadores disponibles',
                  message: 'Prueba otro servicio o vuelve al inicio para explorar categorías.',
                  actionLabel: 'Ver otros servicios',
                  onAction: () => context.go(AppConstants.routeUserHome),
                )
              : Column(
                  children: [
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
                                  value: _sortBy,
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
                                  value: _minRating,
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
                          : RefreshIndicator(
                              onRefresh: _loadWorkers,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredWorkers.length,
                                itemBuilder: (context, index) {
                                  final worker = _filteredWorkers[index];
                                  final user = _users[worker.userId];
                                  final score = _matchScores[worker.userId];
                                  return _WorkerCard(
                                    worker: worker,
                                    user: user,
                                    visitFeeLabel: _currency.format(worker.visitFee),
                                    isRecommended: _isAutomaticMode && score != null,
                                    matchScore: score,
                                    onTap: () {
                                      context.push(
                                        '${AppConstants.routeWorkerDetail}/${worker.userId}',
                                        extra: {'serviceId': widget.serviceId},
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final UserModel? user;
  final String visitFeeLabel;
  final bool isRecommended;
  final double? matchScore;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.worker,
    this.user,
    required this.visitFeeLabel,
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
                          _ChipBadge(
                            icon: Icons.payments_outlined,
                            label: 'Visita $visitFeeLabel',
                            color: AppColors.primaryLight,
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

