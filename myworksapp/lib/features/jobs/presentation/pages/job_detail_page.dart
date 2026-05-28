import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/database/repositories/service_repository.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/job_service.dart';
import '../../../../core/services/job_state_machine.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/database/repositories/job_photo_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class JobDetailPage extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  final JobRepository _jobRepository = JobRepository();
  final UserRepository _userRepository = UserRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final JobPhotoRepository _jobPhotoRepository = JobPhotoRepository();
  final JobService _jobService = JobService.instance;
  final JobStateMachine _stateMachine = JobStateMachine.instance;

  JobModel? _job;
  bool _isLoading = true;
  String? _error;
  String _displayAddress = '';
  bool _isLoadingAddress = true;
  
  // Estados de transiciones válidas (cache)
  Map<String, bool> _canTransition = {};

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final job = await _jobRepository.getJobById(widget.jobId);
      setState(() {
        _job = job;
        _isLoading = false;
      });
      
      if (job != null) {
        _loadAddress(job);
        _loadValidTransitions(job);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Carga las transiciones válidas para el estado actual del job
  Future<void> _loadValidTransitions(JobModel job) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    final transitions = <String, bool>{};
    
    // Verificar cada transición posible
    final possibleStatuses = [
      AppConstants.jobStatusAccepted,
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
    ];

    for (final status in possibleStatuses) {
      final canTransition = _stateMachine.isValidTransition(
        job.status,
        status,
        pricingMode: job.pricingMode,
      );
      transitions[status] = canTransition;
    }

    setState(() {
      _canTransition = transitions;
    });
  }

  Future<void> _loadAddress(JobModel job) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final address = await LocationUtils.getLocationTextForJob(
        address: job.address,
        status: job.status,
        latitude: job.latitude,
        longitude: job.longitude,
      );

      if (mounted) {
        setState(() {
          _displayAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _displayAddress = job.status == AppConstants.jobStatusPending
              ? 'Ubicación aproximada'
              : job.address;
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _updateJobStatus(String newStatus) async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null || _job == null) return;

      // Validar transición usando JobStateMachine
      if (!_stateMachine.isValidTransition(
        _job!.status,
        newStatus,
        pricingMode: _job!.pricingMode,
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se puede cambiar el estado de ${_job!.status} a $newStatus'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ejecutar transición usando JobStateMachine
      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: newStatus,
        userId: user.id,
      );

      await _loadJobDetails();
      
      // Enviar notificación
      if (_job != null) {
        final otherUserId = user.id == _job!.userId ? _job!.workerId : _job!.userId;
        if (otherUserId != null) {
          String title = '';
          String body = '';
          
          switch (newStatus) {
            case AppConstants.jobStatusAccepted:
              title = 'Trabajo Aceptado';
              body = 'Tu solicitud ha sido aceptada por el trabajador';
              break;
            case AppConstants.jobStatusInProgress:
              title = 'Trabajo Iniciado';
              body = 'El trabajador ha iniciado el trabajo';
              break;
            case AppConstants.jobStatusCompleted:
              title = 'Trabajo Completado';
              body = 'El trabajo ha sido finalizado. ¡Califica al trabajador!';
              break;
            case AppConstants.jobStatusCancelled:
              title = 'Trabajo Cancelado';
              body = 'El trabajo ha sido cancelado';
              break;
          }
          
          if (title.isNotEmpty) {
            await NotificationService.instance.showNotification(
              title: title,
              body: body,
              userId: otherUserId,
              type: 'job_${newStatus}',
              relatedId: widget.jobId,
            );
          }
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado')),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptJob() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || _job == null) return;

    // Validar transición usando JobStateMachine
    if (!_stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusAccepted,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede aceptar un trabajo en estado: ${_job!.status}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si el trabajador ya tiene trabajos activos
    final hasActiveJobs = await _jobRepository.hasActiveJobs(user.id);
    if (hasActiveJobs) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes aceptar más trabajos. Completa o cancela tus trabajos actuales primero.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Usar JobStateMachine para la transición
      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: AppConstants.jobStatusAccepted,
        userId: user.id,
      );

      // Asignar trabajador
      await _jobRepository.assignWorker(_job!.id, user.id);
      
      // Actualizar disponibilidad del trabajador a false
      final WorkerRepository _workerRepository = WorkerRepository();
      await _workerRepository.updateAvailability(user.id, false);
      
      await _loadJobDetails();
      
      // Recargar la dirección ahora que el trabajo está aceptado
      if (_job != null) {
        _loadAddress(_job!);
      }

      // Enviar notificación al usuario
      await NotificationService.instance.showNotification(
        title: 'Trabajo Aceptado',
        body: 'Tu solicitud ha sido aceptada por ${user.name}',
        userId: _job!.userId,
        type: 'job_accepted',
        relatedId: widget.jobId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabajo aceptado. Ahora puedes ver la ubicación exacta. No podrás recibir más trabajos hasta completar este.'),
        ),
      );
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeJob() async {
    if (_job == null) return;

    // Validar transición usando JobStateMachine
    if (!_stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusCompleted,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede completar un trabajo en estado: ${_job!.status}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que el trabajador haya subido fotos
    final photoCount = await _jobPhotoRepository.getPhotoCountByJobId(widget.jobId);
    
    if (photoCount == 0) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fotos Requeridas'),
          content: const Text(
            'Debes subir al menos una foto del trabajo antes de completarlo. ¿Quieres subir fotos ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                context.push('${AppConstants.routeJobPhotos}/${widget.jobId}');
              },
              child: const Text('Subir Fotos'),
            ),
          ],
        ),
      );
      
      if (confirm != true) {
        return;
      }
      return; // El usuario irá a subir fotos
    }

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) return;

      // Usar JobStateMachine para la transición
      await _stateMachine.transitionTo(
        jobId: widget.jobId,
        newStatus: AppConstants.jobStatusCompleted,
        userId: user.id,
      );

      await _loadJobDetails();
      
      // Restaurar disponibilidad del trabajador
      if (user.role == AppConstants.roleWorker) {
        final WorkerRepository _workerRepository = WorkerRepository();
        await _workerRepository.updateAvailability(user.id, true);
      }
      
      // Si es usuario, mostrar opción de calificar
      if (user.role == AppConstants.roleUser) {
        if (!mounted) return;
        context.push('${AppConstants.routeRating}/${widget.jobId}');
      }
    } on AppError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelJob(BuildContext context) async {
    if (_job == null) return;

    // Validar transición usando JobStateMachine
    if (!_stateMachine.isValidTransition(
      _job!.status,
      AppConstants.jobStatusCancelled,
      pricingMode: _job!.pricingMode,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede cancelar un trabajo en estado: ${_job!.status}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitud'),
        content: const Text('¿Estás seguro de que quieres cancelar esta solicitud?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authState = ref.read(authProvider);
        final user = authState.user;
        if (user == null) return;

        // Usar JobStateMachine para la transición
        await _stateMachine.transitionTo(
          jobId: widget.jobId,
          newStatus: AppConstants.jobStatusCancelled,
          userId: user.id,
        );

        await _loadJobDetails();
        if (!mounted) return;
        Navigator.pop(context);
      } on AppError catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectJob(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Trabajo'),
        content: const Text('¿Estás seguro de que quieres rechazar este trabajo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, rechazar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateJobStatus(AppConstants.jobStatusCancelled);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: LoadingWidget(),
      );
    }

    if (_error != null || _job == null) {
      return Scaffold(
        appBar: AppGradientAppBar(),
        body: ErrorDisplayWidget(
          message: _error ?? 'Trabajo no encontrado',
          onRetry: _loadJobDetails,
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isWorker = currentUser?.role == AppConstants.roleWorker;
    final isOwner = currentUser?.id == _job!.userId || currentUser?.id == _job!.workerId;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Detalles del Trabajo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(_job!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(_job!.status),
                    color: _getStatusColor(_job!.status),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStatusText(_job!.status),
                    style: TextStyle(
                      color: _getStatusColor(_job!.status),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Descripción
            Text(
              'Descripción',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _job!.description ?? 'Sin descripción',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            // Dirección
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _job!.status == AppConstants.jobStatusPending
                      ? Icons.location_searching
                      : Icons.location_on,
                  color: _job!.status == AppConstants.jobStatusPending
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isLoadingAddress
                          ? const Text('Obteniendo ubicación...')
                          : Text(
                              _displayAddress,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontStyle: _job!.status == AppConstants.jobStatusPending
                                    ? FontStyle.italic
                                    : null,
                              ),
                            ),
                      if (_job!.status == AppConstants.jobStatusPending) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ubicación aproximada. Verás la dirección exacta al aceptar el trabajo',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Mapa (solo si el trabajo está aceptado o en progreso)
            if (_job!.status != AppConstants.jobStatusPending &&
                _job!.latitude != null &&
                _job!.longitude != null) ...[
              const SizedBox(height: 24),
              Text(
                'Ubicación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              // Mapa integrado (requiere Maps SDK)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_job!.latitude!, _job!.longitude!),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('job_location'),
                        position: LatLng(_job!.latitude!, _job!.longitude!),
                      ),
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    mapType: MapType.normal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Botón para abrir en Google Maps externo (siempre disponible)
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${_job!.latitude},${_job!.longitude}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Abrir en Google Maps'),
              ),
            ],
            const SizedBox(height: 24),
            // Acciones según el rol y estado (validadas con JobStateMachine)
            if (isOwner) ...[
              // Cancelación para usuario (solo si está pendiente y transición válida)
              if (!isWorker && 
                  _job!.status == AppConstants.jobStatusPending &&
                  _canTransition[AppConstants.jobStatusCancelled] == true) ...[
                OutlinedButton(
                  onPressed: () => _cancelJob(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Cancelar Solicitud'),
                ),
              ],
              // Acciones para trabajador
              if (isWorker && 
                  _job!.status == AppConstants.jobStatusPending &&
                  _canTransition[AppConstants.jobStatusAccepted] == true) ...[
                ElevatedButton(
                  onPressed: _acceptJob,
                  child: const Text('Aceptar Trabajo'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _rejectJob(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Rechazar'),
                ),
              ],
              if (isWorker && 
                  _job!.status == AppConstants.jobStatusAccepted &&
                  _canTransition[AppConstants.jobStatusInProgress] == true) ...[
                ElevatedButton(
                  onPressed: () => _updateJobStatus(AppConstants.jobStatusInProgress),
                  child: const Text('Iniciar Trabajo'),
                ),
              ],
              if (isWorker && 
                  _job!.status == AppConstants.jobStatusInProgress &&
                  _canTransition[AppConstants.jobStatusCompleted] == true) ...[
                ElevatedButton(
                  onPressed: _completeJob,
                  child: const Text('Finalizar Trabajo'),
                ),
              ],
              if (!isWorker && _job!.status == AppConstants.jobStatusCompleted) ...[
                ElevatedButton(
                  onPressed: () {
                    context.push('${AppConstants.routeRating}/${widget.jobId}');
                  },
                  child: const Text('Calificar Trabajo'),
                ),
              ],
              // Botón de chat (si el trabajo está aceptado o en progreso)
              if ((_job!.status == AppConstants.jobStatusAccepted ||
                      _job!.status == AppConstants.jobStatusInProgress) &&
                  isOwner) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('${AppConstants.routeChat}/${widget.jobId}');
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Abrir Chat'),
                ),
              ],
              // Botón de fotos
              if (isOwner && _job!.status != AppConstants.jobStatusPending) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('${AppConstants.routeJobPhotos}/${widget.jobId}');
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Ver Fotos'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Colors.orange;
      case AppConstants.jobStatusAccepted:
        return Colors.blue;
      case AppConstants.jobStatusInProgress:
        return Colors.purple;
      case AppConstants.jobStatusCompleted:
        return Colors.green;
      case AppConstants.jobStatusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return Icons.pending;
      case AppConstants.jobStatusAccepted:
        return Icons.check_circle_outline;
      case AppConstants.jobStatusInProgress:
        return Icons.work;
      case AppConstants.jobStatusCompleted:
        return Icons.check_circle;
      case AppConstants.jobStatusCancelled:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return 'Pendiente';
      case AppConstants.jobStatusAccepted:
        return 'Aceptado';
      case AppConstants.jobStatusInProgress:
        return 'En Curso';
      case AppConstants.jobStatusCompleted:
        return 'Completado';
      case AppConstants.jobStatusCancelled:
        return 'Cancelado';
      default:
        return status;
    }
  }
}

