import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/domain/catalog_order.dart';
import '../../../../core/domain/user_location_context.dart';
import '../../../../core/database/repositories/worker_schedule_repository.dart';
import '../../../../core/domain/weekly_schedule.dart';
import '../../../../core/services/matching_service.dart';
import '../../../../core/services/user_location_service.dart';
import '../../../../core/domain/transport_surcharge.dart';
import '../../../../core/domain/worker_highlight.dart';
import '../../../../core/domain/worker_public_stats.dart';
import '../../../../core/services/worker_reputation_service.dart';
import '../../../../core/utils/chile_comunas.dart';
import '../../../../core/utils/platform_support.dart';
import '../../../../core/utils/worker_zone_matcher.dart';
import '../../../../core/widgets/design_system/loading_skeleton.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/widgets/design_system/primary_button.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/worker_card.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../widgets/worker_list_chrome.dart';
import '../widgets/worker_search_map.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/search_text.dart';
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
  final _addressController = TextEditingController();
  final _listController = ScrollController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  List<WorkerModel> _workers = [];
  List<WorkerModel> _filteredWorkers = [];
  Map<String, UserModel> _users = {};
  Map<String, double> _matchScores =
      {}; // Para mostrar scores en modo automático
  Set<String> _busyWorkerIds = {};
  UserLocationContext? _userLocation;
  bool _isLoading = true;
  bool _isAutomaticMode = false; // false = Manual, true = Inteligente
  /// `cercania` = orden único del catálogo (cercanía, nota, precio), igual que la web.
  String _sortBy = 'cercania';
  double _minRating = lowRatingFloor;
  bool _onlyNow = false;
  Map<String, WeeklySchedule> _schedules = {};
  String? _serviceName;
  String? _selectedWorkerId;
  bool _mapExpanded = false;
  bool _mapReady = false;
  bool _mapMountScheduled = false;
  final _mapKey = GlobalKey();
  bool _locatingGps = false;
  bool _locatingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _listController.dispose();
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

  bool _matchesWorkerSearch({
    required String query,
    required String name,
    required String profession,
  }) {
    final raw = query.trim();
    if (raw.isEmpty) return true;
    final needle = foldSearchText(raw);
    final haystack = foldSearchText('$name $profession');
    if (haystack.contains(needle)) return true;
    final parts = needle
        .split(RegExp(r'\s+'))
        .where((part) => part.length >= 3);
    return parts.any(haystack.contains);
  }

  void _filterWorkers() {
    if (!mounted) return;
    setState(() {
      _filteredWorkers = _workers.where((worker) {
        final user = _users[worker.userId];
        final matchesSearch = _matchesWorkerSearch(
          query: _searchController.text,
          name: user?.name ?? '',
          profession: worker.profession,
        );
        final matchesRating = passesMinRating(worker.rating, _minRating);
        final schedule = _schedules[worker.userId];
        final matchesNow =
            !_onlyNow ||
            countsAsAvailableNow(
              manuallyAvailable: worker.isAvailable,
              schedule: schedule,
              instant: DateTime.now(),
            );
        return matchesSearch && matchesRating && matchesNow;
      }).toList();

      // Primero el orden único; precio y nota son vistas opcionales que
      // desempatan con ese mismo orden (List.sort de Dart no es estable).
      WorkerReputationService.instance.sortForListing(
        _filteredWorkers,
        clientLatitude: _userLocation?.latitude,
        clientLongitude: _userLocation?.longitude,
      );
      if (_sortBy == 'precio') {
        stableSortBy(_filteredWorkers, (a, b) => a.visitFee.compareTo(b.visitFee));
      } else if (_sortBy == 'calificacion') {
        stableSortBy(_filteredWorkers, (a, b) => b.rating.compareTo(a.rating));
      }

      final stillVisible = _filteredWorkers.any(
        (worker) => worker.userId == _selectedWorkerId,
      );
      if (!stillVisible) {
        WorkerModel? firstPlaced;
        for (final worker in _filteredWorkers) {
          if (worker.baseLatitude != null && worker.baseLongitude != null) {
            firstPlaced = worker;
            break;
          }
        }
        _selectedWorkerId =
            firstPlaced?.userId ??
            (_filteredWorkers.isEmpty ? null : _filteredWorkers.first.userId);
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
    // Fallback por defecto para asegurar que siempre haya ubicación y se muestren los trabajadores demo
    _userLocation ??= const UserLocationContext(
      city: 'Puerto Montt',
      region: 'Los Lagos',
      latitude: UserLocationService.demoFallbackLatitude,
      longitude: UserLocationService.demoFallbackLongitude,
    );
  }

  Future<void> _selectCityManually() async {
    String? selected = _userLocation?.city ?? 'Puerto Montt';
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

  /// Tope para que la lista nunca quede en el esqueleto de carga.
  static const _locationTimeout = Duration(seconds: 8);
  static const _loadTimeout = Duration(seconds: 20);
  int _loadGeneration = 0;

  Future<void> _loadWorkers() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    setState(() => _isLoading = true);

    try {
      try {
        await _resolveUserLocation().timeout(_locationTimeout);
      } catch (_) {
        // GPS o geocodificación lentos: seguimos con la ciudad de la demo.
        _userLocation ??= const UserLocationContext(
          city: 'Puerto Montt',
          region: 'Los Lagos',
          latitude: UserLocationService.demoFallbackLatitude,
          longitude: UserLocationService.demoFallbackLongitude,
        );
      }
      if (!mounted || generation != _loadGeneration) return;
      if (_isAutomaticMode &&
          widget.jobId != null &&
          widget.serviceId != null) {
        await _loadAutomaticMatching().timeout(_loadTimeout);
      } else {
        await _loadManualWorkers().timeout(_loadTimeout);
      }
    } on TimeoutException {
      if (!mounted || generation != _loadGeneration) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La búsqueda tardó demasiado. Revisa tu conexión y desliza para reintentar.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.userMessage(
              e,
              fallback: 'No se pudo cargar el listado. Desliza para reintentar.',
            ),
          ),
        ),
      );
    } finally {
      // Pase lo que pase, nunca dejamos la pantalla pegada en "cargando".
      if (mounted && generation == _loadGeneration && _isLoading) {
        setState(() => _isLoading = false);
      }
      _revealMapSoon();
    }
  }

  /// El mapa entra un frame después de la lista. Si nace en el mismo frame,
  /// decodificar las baldosas traba el primer toque en el teléfono.
  void _revealMapSoon() {
    if (!mounted || _mapReady || _mapMountScheduled) return;
    _mapMountScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mapReady = true);
    });
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
      final JobRepository jobRepository = JobRepository();
      final job = await jobRepository.getJobById(widget.jobId!);

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
      await _refreshSchedules();
    } catch (e) {
      // Si falla matching automático, cargar manual
      await _loadManualWorkers();
    }
  }

  Future<void> _loadManualWorkers() async {
    List<WorkerModel> workers;

    if (widget.serviceId != null) {
      final service = await _serviceRepository.getServiceById(
        widget.serviceId!,
      );
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

    _busyWorkerIds = {};

    // Perfiles públicos en una sola llamada (antes era 1 llamada por profesional).
    final users = await _userRepository.getPublicProfilesByIds(
      workers.map((w) => w.userId).toList(),
    );

    if (!mounted) return;
    setState(() {
      _workers = workers;
      _users = users;
      _matchScores = {};
      _isLoading = false;
    });
    _filterWorkers();
    await _refreshSchedules();
  }

  Future<void> _refreshSchedules() async {
    try {
      final schedules = await WorkerScheduleRepository().loadMany(
        _workers.map((worker) => worker.userId).toList(),
      );
      if (!mounted) return;
      setState(() => _schedules = schedules);
      _filterWorkers();
    } catch (_) {
      // Sin la migración el listado sigue usando el interruptor disponible.
    }
  }

  void _openWorker(WorkerModel worker) {
    context.push(
      '${AppConstants.routeWorkerDetail}/${worker.userId}',
      extra: {'serviceId': widget.serviceId},
    );
  }

  void _selectWorkerOnMap(WorkerModel worker) {
    setState(() => _selectedWorkerId = worker.userId);
    final index = _filteredWorkers.indexWhere(
      (item) => item.userId == worker.userId,
    );
    if (index < 0 || !_listController.hasClients) return;
    _listController.animateTo(
      (index * 120.0).clamp(0, _listController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _applyClientLocation(UserLocationContext location) async {
    final cityChanged = _userLocation?.city != location.city;
    setState(() => _userLocation = location);
    if (cityChanged) {
      await _loadWorkers();
    } else {
      _filterWorkers();
    }
  }

  Future<void> _useGps() async {
    setState(() => _locatingGps = true);
    try {
      final location = await UserLocationService.instance.getCurrent();
      if (!mounted) return;
      if (location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se leyó el GPS. Escribe una dirección o marca el punto en el mapa.',
            ),
          ),
        );
        return;
      }
      _addressController.text = location.displayLabel;
      await _applyClientLocation(location);
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.length < 3) return;
    setState(() => _locatingAddress = true);
    try {
      final location = await UserLocationService.instance.fromAddress(query);
      if (!mounted) return;
      if (location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No encontramos esa dirección. Prueba con calle y ciudad, o marca el punto en el mapa.',
            ),
          ),
        );
        return;
      }
      _addressController.text = location.displayLabel;
      await _applyClientLocation(location);
    } finally {
      if (mounted) setState(() => _locatingAddress = false);
    }
  }

  Future<void> _pickClientLocation(double latitude, double longitude) async {
    final location = await UserLocationService.instance.fromCoordinates(
      latitude,
      longitude,
    );
    if (!mounted) return;
    _addressController.text = location.displayLabel;
    await _applyClientLocation(location);
  }

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: AppDecorations.canvasOf(context),
      appBar: AppGradientAppBar(
        title: Text(_serviceName ?? 'Trabajadores disponibles'),
        actions: [
          IconButton(
            tooltip: _mapExpanded ? 'Ver lista' : 'Ampliar mapa',
            onPressed: () => setState(() => _mapExpanded = !_mapExpanded),
            icon: Icon(
              _mapExpanded ? Icons.view_list_rounded : Icons.map_outlined,
              color: AppColors.brandOrange,
            ),
          ),
        ],
      ),
      body: _boundedBody(_buildBody()),
    );

    return page;
  }

  Widget _boundedBody(Widget child) {
    final media = MediaQuery.of(context);
    final height = (media.size.height - media.padding.top - kToolbarHeight)
        .clamp(240.0, media.size.height);
    return SizedBox(height: height, width: double.infinity, child: child);
  }

  Widget _buildBody() {
    if (_isLoading && _workers.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: 5,
        itemBuilder: (context, index) => const ListItemSkeleton(),
      );
    }
    if (_userLocation == null) {
      return _LocationRequiredState(
        onRetry: _loadWorkers,
        onSelectCity: _selectCityManually,
        isDesktop: AppPlatform.isDesktopNative,
      );
    }
    // El mapa queda fijo en el árbol (misma GlobalKey al ampliar). Si vive
    // dentro del scroll, al salir de pantalla se destruye y al volver —o al
    // abrir el mapa solo— baja todas las baldosas otra vez y se pega.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLocationHeader(),
        if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        if (_mapExpanded)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _mapSlot(showSelectedCard: true),
            ),
          )
        else ...[
          SizedBox(
            height: 260,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _mapSlot(showSelectedCard: false, showLocationBar: false),
            ),
          ),
          Expanded(child: _buildScrollableResults()),
        ],
      ],
    );
  }

  Widget _mapSlot({
    required bool showSelectedCard,
    bool showLocationBar = true,
  }) {
    if (!_mapReady) return const _MapPlaceholder();
    return _buildMap(
      showSelectedCard: showSelectedCard,
      showLocationBar: showLocationBar,
    );
  }

  Widget _buildScrollableResults() {
    return RefreshIndicator(
      onRefresh: _loadWorkers,
      child: CustomScrollView(
        controller: _listController,
        slivers: [
          SliverToBoxAdapter(child: _buildMapLocationRow()),
          if (widget.jobId != null && widget.serviceId != null)
            SliverToBoxAdapter(child: _buildMatchingToggle()),
          if (!_isAutomaticMode) SliverToBoxAdapter(child: _buildFilters()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: _buildWorkerSliver(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.grayLight,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Modo de búsqueda',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkerListAvailableNowTile(
          value: _onlyNow,
          onChanged: (value) {
            setState(() => _onlyNow = value);
            _filterWorkers();
          },
        ),
        WorkerListFilters(
          searchController: _searchController,
          sortBy: _sortBy,
          minRating: _minRating,
          onSortChanged: (value) {
            setState(() => _sortBy = value);
            _filterWorkers();
          },
          onMinRatingChanged: (value) {
            setState(() => _minRating = value);
            _filterWorkers();
          },
        ),
      ],
    );
  }

  Widget _buildLocationHeader() {
    return WorkerListLocationHeader(
      label: _userLocation!.displayLabel,
      onChangeCity: _selectCityManually,
    );
  }

  Widget _buildMap({
    required bool showSelectedCard,
    bool showLocationBar = true,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: WorkerSearchMap(
        key: _mapKey,
        workers: _filteredWorkers,
        users: _users,
        selectedWorkerId: _selectedWorkerId,
        clientLatitude: _userLocation?.latitude,
        clientLongitude: _userLocation?.longitude,
        categoryLabel: _serviceName,
        onSelectWorker: _selectWorkerOnMap,
        onPickClientLocation: _pickClientLocation,
        onOpenWorker: _openWorker,
        addressController: _addressController,
        onSearchAddress: _searchAddress,
        onUseGps: _useGps,
        locatingGps: _locatingGps,
        locatingAddress: _locatingAddress,
        showSelectedCard: showSelectedCard,
        showLocationBar: showLocationBar,
      ),
    );
  }

  Widget _buildMapLocationRow() {
    return WorkerListAddressRow(
      addressController: _addressController,
      onSearch: _searchAddress,
      onUseGps: _useGps,
      locatingAddress: _locatingAddress,
      locatingGps: _locatingGps,
      hasFix: _userLocation?.latitude != null,
    );
  }

  Widget _buildWorkerSliver() {
    if (_workers.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          icon: Icons.person_off,
          title: 'No hay trabajadores en tu ciudad',
          message:
              'Solo mostramos profesionales en ${_userLocation?.city ?? 'tu ciudad'}. Marca otro punto o cambia de ciudad.',
          actionLabel: 'Ver otros servicios',
          onAction: () => context.go(AppConstants.routeUserHome),
          secondaryActionLabel: 'Cambiar ciudad',
          onSecondaryAction: _selectCityManually,
        ),
      );
    }
    if (_filteredWorkers.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          icon: Icons.search_off,
          title: 'No se encontraron trabajadores',
          message: 'Intenta con otros filtros o busca otro servicio',
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final worker = _filteredWorkers[index];
        final user = _users[worker.userId];
        final score = _matchScores[worker.userId];
        final isBusy = _busyWorkerIds.contains(worker.userId);
        final isRecommended = _isAutomaticMode && score != null;
        final elite = isEliteWorker(worker);
        final coverage = coverageNotice(
          worker: worker,
          clientLatitude: _userLocation?.latitude,
          clientLongitude: _userLocation?.longitude,
        );
        final selected = worker.userId == _selectedWorkerId;
        final card = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(color: AppColors.brandOrange, width: 2)
                : null,
          ),
          child: WorkerCard(
            name: user?.name ?? 'Trabajador',
            profession: worker.profession,
            footnote: coverage.text,
            leading: ProfileAvatarView(
              displayName: user?.name ?? 'Trabajador',
              photoPath: user?.profilePhotoPath,
              radius: 26,
              onDarkBackground: Theme.of(context).brightness == Brightness.dark,
            ),
            headerBadge: elite
                ? 'Élite del mes'
                : isRecommended
                ? 'Recomendado ${(score * 100).toStringAsFixed(0)}%'
                : null,
            headerBadgeColor: elite ? const Color(0xFFB45309) : null,
            badges: [
              if (elite)
                const WorkerCardBadge(
                  icon: Icons.workspace_premium,
                  label: 'Destacado',
                  color: Color(0xFFB45309),
                ),
              WorkerCardBadge(
                icon: Icons.star_rounded,
                label: WorkerPublicStats.ratingLabel(worker.rating),
                color: AppColors.warning,
              ),
              if (worker.workZone != null)
                WorkerCardBadge(
                  icon: Icons.location_on_outlined,
                  label: worker.workZone!,
                  color: AppColors.grayMedium,
                ),
              WorkerCardBadge(
                icon: Icons.radar_rounded,
                label: '${formatServiceRadiusKm(worker.serviceRadiusKm)} km sin extra',
                color: AppColors.brandOrange,
              ),
              if (isBusy)
                const WorkerCardBadge(
                  icon: Icons.schedule,
                  label: 'Ocupado',
                  color: AppColors.brandOrange,
                ),
            ],
            showChevron: true,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
            onTap: () {
              setState(() => _selectedWorkerId = worker.userId);
              _openWorker(worker);
            },
          ),
        );
        return card;
      }, childCount: _filteredWorkers.length),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFE8EEF3),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppDecorations.appleCardShadow(isDark: isDark),
            border: Border.all(
              color: isDark
                  ? AppColors.grayBorder.withValues(alpha: 0.1)
                  : AppColors.grayBorder.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 36,
                  color: AppColors.brandOrange,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ubicación para Profesionales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.brandNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona tu ciudad o permite el acceso a ubicación para ver profesionales cercanos a ti.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? AppColors.grayLight : AppColors.grayMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Buscar profesionales en mi ciudad',
                onPressed: onSelectCity,
                icon: Icons.location_city_rounded,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar GPS'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
