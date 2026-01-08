import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/job_photo_repository.dart';
import '../../../../core/database/repositories/portfolio_repository.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/portfolio_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WorkerDetailPage extends ConsumerStatefulWidget {
  final String workerId;

  const WorkerDetailPage({super.key, required this.workerId});

  @override
  ConsumerState<WorkerDetailPage> createState() => _WorkerDetailPageState();
}

class _WorkerDetailPageState extends ConsumerState<WorkerDetailPage> {
  final WorkerRepository _workerRepository = WorkerRepository();
  final UserRepository _userRepository = UserRepository();
  final JobRepository _jobRepository = JobRepository();
  final JobPhotoRepository _jobPhotoRepository = JobPhotoRepository();
  final PortfolioRepository _portfolioRepository = PortfolioRepository();

  WorkerModel? _worker;
  UserModel? _user;
  List<PortfolioModel> _portfolio = [];
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

      setState(() {
        _worker = worker;
        _user = user;
        _portfolio = portfolio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _requestService() async {
    // Obtener el último trabajo pendiente del usuario actual
    // y asignarlo a este trabajador
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) return;

    try {
      final userJobs = await _jobRepository.getJobsByUserId(user.id);
      JobModel? pendingJob;
      try {
        pendingJob = userJobs.firstWhere(
          (job) => job.status == AppConstants.jobStatusPending,
        );
      } catch (e) {
        pendingJob = null;
      }

      if (pendingJob == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primero debes crear una solicitud de servicio'),
          ),
        );
        context.push(AppConstants.routeServiceRequest);
        return;
      }

      await _jobRepository.assignWorker(pendingJob.id, widget.workerId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trabajador asignado exitosamente')),
      );

      context.push('${AppConstants.routeJobDetail}/${pendingJob.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(),
      );
    }

    if (_error != null || _worker == null || _user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorStateWidget(
          title: 'Error al cargar perfil',
          message: _error ?? 'Trabajador no encontrado',
          actionLabel: 'Reintentar',
          onRetry: _loadWorkerDetails,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Trabajador'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con foto y nombre
            Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      _user!.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _worker!.profession,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _worker!.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Descripción
            if (_worker!.description != null) ...[
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre mí',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _worker!.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
            // Estado de disponibilidad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _worker!.isAvailable
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _worker!.isAvailable ? Icons.check_circle : Icons.cancel,
                      color: _worker!.isAvailable ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _worker!.isAvailable
                          ? 'Disponible para trabajar'
                          : 'No disponible en este momento',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Portafolio de trabajos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portafolio',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _portfolio.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.photo_library_outlined,
                          title: 'Sin fotos de trabajos',
                          message: 'Este trabajador aún no ha subido fotos de sus trabajos',
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _portfolio.length,
                          itemBuilder: (context, index) {
                            final photo = _portfolio[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(photo.photoPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Botón de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                onPressed: _worker!.isAvailable ? _requestService : null,
                child: const Text('Solicitar Servicio'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

