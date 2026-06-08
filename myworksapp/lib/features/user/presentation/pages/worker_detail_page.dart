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
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/service_worker_mapper.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
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
      return const Scaffold(body: LoadingWidget());
    }

    if (_error != null || _worker == null || _user == null) {
      return Scaffold(
        appBar: AppGradientAppBar(),
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
      appBar: AppGradientAppBar(
        title: const Text('Perfil del trabajador'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppDecorations.headerGradient,
                borderRadius: BorderRadius.circular(22),
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
                      radius: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user!.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _worker!.profession,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warning, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        _worker!.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        _isAcceptingJobs ? Icons.check_circle : Icons.cancel,
                        color: _isAcceptingJobs ? AppColors.success : Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isAcceptingJobs ? 'Disponible' : 'Ocupado',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildAboutCard(context),
            const SizedBox(height: 14),
            Text('Trabajos anteriores', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _portfolio.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.photo_library_outlined,
                    title: 'Sin trabajos publicados',
                    message: 'Este trabajador aún no ha subido fotos o videos.',
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _portfolio.length,
                    itemBuilder: (context, index) {
                      final item = _portfolio[index];
                      return PortfolioMediaTile(
                        photoPath: item.photoPath,
                        mediaType: item.mediaType,
                        description: item.description,
                      );
                    },
                  ),
            const SizedBox(height: 20),
            WorkerReviewsSection(
              reviews: _reviews,
              averageRating: _worker!.rating,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isAcceptingJobs ? _openServiceRequest : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Crear solicitud de servicio'),
            ),
            if (!_isAcceptingJobs) ...[
              const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sobre mí',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          Text(
            'Especialidad',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.grayMedium,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(context, Icons.handyman_outlined, _worker!.profession),
              _infoChip(context, Icons.category_outlined, categoryLabel),
              _infoChip(
                context,
                Icons.star_rounded,
                '${_worker!.rating.toStringAsFixed(1)} de calificación',
              ),
              if (_reviews.isNotEmpty)
                _infoChip(
                  context,
                  Icons.chat_bubble_outline,
                  '${_reviews.length} ${_reviews.length == 1 ? 'opinión' : 'opiniones'}',
                ),
              _infoChip(
                context,
                Icons.photo_library_outlined,
                _portfolio.isEmpty
                    ? 'Portafolio en construcción'
                    : '${_portfolio.length} ${_portfolio.length == 1 ? 'trabajo' : 'trabajos'} publicados',
              ),
              _infoChip(
                context,
                _isAcceptingJobs ? Icons.event_available_outlined : Icons.schedule_outlined,
                _isAcceptingJobs ? 'Disponible ahora' : 'Agenda ocupada',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
          ),
        ],
      ),
    );
  }
}
