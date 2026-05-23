import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/models/portfolio_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/repositories/portfolio_repository.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/portfolio_media_tile.dart';
import '../../../../core/widgets/price_summary_card.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
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

  WorkerModel? _worker;
  UserModel? _user;
  List<PortfolioModel> _portfolio = [];
  String? _resolvedServiceId;
  bool _isLoading = true;
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
      final user = await _userRepository.getUserById(widget.workerId);
      final portfolio = await _portfolioRepository.getPortfolioByWorkerId(widget.workerId);

      String? serviceId = widget.serviceId;
      if (serviceId == null && worker != null) {
        final services = await _serviceRepository.getServicesByCategory(worker.serviceCategory);
        if (services.isNotEmpty) serviceId = services.first.id;
      }

      setState(() {
        _worker = worker;
        _user = user;
        _portfolio = portfolio;
        _resolvedServiceId = serviceId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _openQuickBooking() {
    if (_resolvedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo determinar el servicio')),
      );
      return;
    }

    context.push(
      AppConstants.routeQuickBooking,
      extra: {
        'serviceId': _resolvedServiceId,
        'workerId': widget.workerId,
      },
    );
  }

  void _openFullRequest() {
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
                  ProfileAvatarView(
                    displayName: _user!.name,
                    photoPath: _user!.profilePhotoPath,
                    radius: 40,
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
                        _worker!.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: _worker!.isAvailable ? AppColors.success : Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _worker!.isAvailable ? 'Disponible' : 'Ocupado',
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
            PriceSummaryCard(
              visitFee: _worker!.visitFee,
              workerName: _user!.name,
            ),
            if (_worker!.description != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.surfaceCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sobre mí', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(_worker!.description!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
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
            ElevatedButton(
              onPressed: _worker!.isAvailable ? _openQuickBooking : null,
              child: const Text('Agendar visita'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _worker!.isAvailable ? _openFullRequest : null,
              child: const Text('Crear solicitud de servicio'),
            ),
          ],
        ),
      ),
    );
  }
}
