import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/models/portfolio_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/models/worker_review_model.dart';
import '../../../../core/database/repositories/portfolio_repository.dart';
import '../../../../core/database/repositories/rating_repository.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/service_worker_mapper.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/design_system/before_after_slider.dart';
import '../../../../core/widgets/design_system/myworks_guarantee_badge.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/design_system/loading_skeleton.dart';
import '../../../../core/widgets/portfolio_media_tile.dart';
import '../../../../core/widgets/portfolio_media_viewer.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../widgets/worker_reviews_section.dart';
class WorkerDetailPage extends ConsumerStatefulWidget {
  final String workerId;
  final String? serviceId;

  const WorkerDetailPage({
    super.key,
    required this.workerId,
    this.serviceId,
  });

  @override
  ConsumerState<WorkerDetailPage> createState() => _WorkerDetailPageState();
}

class _WorkerDetailPageState extends ConsumerState<WorkerDetailPage> {
  final WorkerRepository _workerRepository = WorkerRepository();
  final UserRepository _userRepository = UserRepository();
  final PortfolioRepository _portfolioRepository = PortfolioRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final RatingRepository _ratingRepository = RatingRepository();

  WorkerModel? _worker;
  UserModel? _user;
  List<PortfolioModel> _portfolio = [];
  List<WorkerReviewModel> _reviews = [];
  String? _resolvedServiceId;
  bool _isLoading = true;
  bool _isAcceptingJobs = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkerDetails();
  }

  Future<void> _loadWorkerDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final worker = await _workerRepository.getWorkerByUserId(widget.workerId);
      await _workerRepository.enforceUnavailableWhileBusy(widget.workerId);
      final acceptingJobs =
          await _workerRepository.isWorkerAcceptingJobs(widget.workerId);
      final user = await _userRepository.getUserById(widget.workerId);
      final portfolio =
          await _portfolioRepository.getPortfolioByWorkerId(widget.workerId);
      final reviews =
          await _ratingRepository.getWorkerReviewsForProfile(widget.workerId);

      String? serviceId = widget.serviceId;
      if (serviceId == null && worker != null) {
        final services = await _serviceRepository.getServicesByCategory(worker.serviceCategory);
        if (services.isNotEmpty) serviceId = services.first.id;
      }

      setState(() {
        _worker = worker;
        _user = user;
        _portfolio = portfolio;
        _reviews = reviews;
        _resolvedServiceId = serviceId;
        _isAcceptingJobs = acceptingJobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _openServiceRequest() {
    if (_resolvedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo determinar el servicio')),
      );
      return;
    }

    context.push(
      AppConstants.routeServiceRequest,
      extra: {
        'serviceId': _resolvedServiceId,
        'workerId': widget.workerId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: const AppGradientAppBar(
          title: Text('Perfil del trabajador'),
        ),
        body: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              ListItemSkeleton(),
              SizedBox(height: 8),
              ListItemSkeleton(),
            ],
          ),
        ),
      );
    }

    if (_error != null || _worker == null || _user == null) {
      return Scaffold(
        appBar: const AppGradientAppBar(),
        body: ErrorStateWidget(
          title: 'Error al cargar perfil',
          message: _error ?? 'Trabajador no encontrado',
          actionLabel: 'Reintentar',
          onRetry: _loadWorkerDetails,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDecorations.screenBackground,
      appBar: const AppGradientAppBar(
        title: Text('Perfil del trabajador'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: AppSpacing.md),
                  _buildAboutCard(context),
                  const SizedBox(height: AppSpacing.md),
                  _buildPortfolioSection(context),
                  const SizedBox(height: AppSpacing.md),
                  WorkerReviewsSection(
                    reviews: _reviews,
                    averageRating: _worker!.rating,
                  ),
                ],
              ),
            ),
          ),
          _buildRequestFooter(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        gradient: AppDecorations.headerGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.headerShadow,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              final path = _user!.profilePhotoPath;
              if (path == null || path.isEmpty) return;
              PortfolioMediaViewer.openImagePath(
                context,
                imagePath: path,
                title: _user!.name,
                description: _worker!.profession,
              );
            },
            child: ProfileAvatarView(
              displayName: _user!.name,
              photoPath: _user!.profilePhotoPath,
              radius: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _user!.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              const ProWorkerBadge(),
            ],
          ),
          Text(
            _worker!.profession,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                _worker!.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Icon(
                _isAcceptingJobs ? Icons.check_circle : Icons.cancel,
                color: _isAcceptingJobs
                    ? AppColors.success
                    : AppColors.white.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                _isAcceptingJobs ? 'Disponible' : 'Ocupado',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestFooter(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grayDark.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _isAcceptingJobs ? _openServiceRequest : null,
                child: const Text('Crear solicitud de servicio'),
              ),
              if (!_isAcceptingJobs) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Este profesional no está disponible en este momento.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grayMedium,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final categoryLabel = ServiceWorkerMapper.categoryLabels[_worker!.serviceCategory] ??
        _worker!.profession;
    final rawDescription = _worker!.description?.trim() ?? '';
    final description = rawDescription.isNotEmpty
        ? rawDescription
        : 'Profesional de $categoryLabel comprometido con un trabajo de calidad, '
            'puntualidad y atención cercana. Evalúo cada solicitud en detalle para '
            'entregarte una propuesta clara antes de comenzar.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.primaryLight, size: 18),
              const SizedBox(width: 8),
              Text(
                'Sobre mí',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            'Especialidad',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.grayMedium,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSpecialtyChips(context, categoryLabel),
        ],
      ),
    );
  }

  Widget _buildSpecialtyChips(BuildContext context, String categoryLabel) {
    final chips = <Widget>[
      _infoChip(context, Icons.handyman_outlined, _worker!.profession, compact: true),
      _infoChip(context, Icons.category_outlined, categoryLabel, compact: true),
      _infoChip(
        context,
        Icons.star_rounded,
        _worker!.rating.toStringAsFixed(1),
        compact: true,
      ),
      if (_reviews.isNotEmpty)
        _infoChip(
          context,
          Icons.chat_bubble_outline,
          '${_reviews.length} ${_reviews.length == 1 ? 'opinión' : 'opiniones'}',
          compact: true,
        ),
      _infoChip(
        context,
        Icons.photo_library_outlined,
        _portfolio.isEmpty
            ? 'Sin portafolio'
            : '${_portfolio.length} trabajos',
        compact: true,
      ),
      _infoChip(
        context,
        _isAcceptingJobs ? Icons.event_available_outlined : Icons.schedule_outlined,
        _isAcceptingJobs ? 'Disponible' : 'Ocupado',
        compact: true,
      ),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  Widget _buildPortfolioSection(BuildContext context) {
    const thumbSize = 84.0;
    const spacing = AppSpacing.sm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Trabajos anteriores',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (_portfolio.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_portfolio.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.grayMedium,
                    ),
              ),
            ],
          ],
        ),
        if (_portfolio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Toca una miniatura para ver foto o video',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.grayMedium,
                ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        const BeforeAfterSlider(
          title: 'Transformación Destacada (Antes vs Después)',
          beforeImageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600',
          afterImageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600',
          height: 210,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_portfolio.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Este trabajador aún no ha subido fotos o videos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayMedium,
                  ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = _portfolio.length * thumbSize +
                  (_portfolio.length - 1) * spacing;
              final fits = totalWidth <= constraints.maxWidth;

              if (fits) {
                return SizedBox(
                  height: thumbSize,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _portfolio.length; i++) ...[
                          if (i > 0) const SizedBox(width: spacing),
                          SizedBox(
                            width: thumbSize,
                            height: thumbSize,
                            child: PortfolioMediaTile(
                              photoPath: _portfolio[i].photoPath,
                              mediaType: _portfolio[i].mediaType,
                              description: _portfolio[i].description,
                              showDescription: false,
                              compact: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: thumbSize,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _portfolio.length,
                  separatorBuilder: (_, __) => const SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    final item = _portfolio[index];
                    return SizedBox(
                      width: thumbSize,
                      child: PortfolioMediaTile(
                        photoPath: item.photoPath,
                        mediaType: item.mediaType,
                        description: item.description,
                        showDescription: false,
                        compact: true,
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _infoChip(
    BuildContext context,
    IconData icon,
    String label, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm + 2 : AppSpacing.md,
        vertical: compact ? AppSpacing.xs + 2 : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: AppColors.primaryLight),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.xs + 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                  fontSize: compact ? 11.5 : null,
                ),
          ),
        ],
      ),
    );
  }
}
