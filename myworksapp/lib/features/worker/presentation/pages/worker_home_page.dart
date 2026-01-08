import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WorkerHomePage extends ConsumerStatefulWidget {
  const WorkerHomePage({super.key});

  @override
  ConsumerState<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends ConsumerState<WorkerHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JobRepository _jobRepository = JobRepository();
  final WorkerRepository _workerRepository = WorkerRepository();
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    try {
      final worker = await _workerRepository.getWorkerByUserId(user.id);
      if (worker != null) {
        // Verificar si tiene trabajos activos
        final hasActiveJobs = await _jobRepository.hasActiveJobs(user.id);
        
        setState(() {
          // Si tiene trabajos activos, no puede estar disponible para nuevos trabajos
          _isAvailable = worker.isAvailable && !hasActiveJobs;
        });
      }
    } catch (e) {
      // Error al cargar disponibilidad
    }
  }

  Future<void> _toggleAvailability() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    // Verificar si tiene trabajos activos
    final hasActiveJobs = await _jobRepository.hasActiveJobs(user.id);
    if (hasActiveJobs) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes cambiar tu disponibilidad mientras tienes trabajos activos. Completa o cancela tus trabajos actuales primero.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final newAvailability = !_isAvailable;
      await _workerRepository.updateAvailability(user.id, newAvailability);
      setState(() {
        _isAvailable = newAvailability;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newAvailability
                ? 'Ahora estás disponible'
                : 'Ya no estás disponible',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Trabajos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              context.push(AppConstants.routeNotifications);
            },
            tooltip: 'Notificaciones',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              context.push(AppConstants.routeJobSchedule);
            },
            tooltip: 'Calendario',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              context.push(AppConstants.routeStatistics);
            },
            tooltip: 'Estadísticas',
          ),
          IconButton(
            icon: Icon(_isAvailable ? Icons.toggle_on : Icons.toggle_off),
            onPressed: _toggleAvailability,
            tooltip: _isAvailable ? 'Disponible' : 'No disponible',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.push(AppConstants.routeWorkerProfile);
            },
            tooltip: 'Perfil',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'En Curso'),
            Tab(text: 'Finalizados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobsList(user.id, AppConstants.jobStatusPending),
          _buildJobsList(user.id, AppConstants.jobStatusInProgress),
          _buildJobsList(user.id, AppConstants.jobStatusCompleted),
        ],
      ),
    );
  }

  Widget _buildJobsList(String workerId, String status) {
    return FutureBuilder<List<JobModel>>(
      future: _getJobsByStatus(workerId, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final jobs = snapshot.data ?? [];

        if (jobs.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.work_outline,
            title: 'No hay trabajos',
            message: status == AppConstants.jobStatusPending
                ? 'Las solicitudes aparecerán aquí'
                : 'No tienes trabajos en este estado',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return _JobCard(
              job: job,
              onTap: () {
                context.push('${AppConstants.routeJobDetail}/${job.id}');
              },
            );
          },
        );
      },
    );
  }

  Future<List<JobModel>> _getJobsByStatus(String workerId, String status) async {
    if (status == AppConstants.jobStatusPending) {
      // Para pendientes, obtener trabajos sin worker asignado
      // Solo mostrar si el trabajador no tiene trabajos activos
      final hasActiveJobs = await _jobRepository.hasActiveJobs(workerId);
      if (hasActiveJobs) {
        return []; // No mostrar trabajos pendientes si tiene activos
      }
      final allJobs = await _jobRepository.getJobsByStatus(status);
      return allJobs.where((job) => job.workerId == null).toList();
    } else {
      final allJobs = await _jobRepository.getJobsByWorkerId(workerId);
      return allJobs.where((job) => job.status == status).toList();
    }
  }
}

class _JobCard extends StatefulWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  String _displayAddress = '';
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final address = await LocationUtils.getLocationTextForJob(
        address: widget.job.address,
        status: widget.job.status,
        latitude: widget.job.latitude,
        longitude: widget.job.longitude,
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
          _displayAddress = widget.job.status == AppConstants.jobStatusPending
              ? 'Ubicación aproximada'
              : widget.job.address;
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.job.description ?? 'Sin descripción',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.job.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(widget.job.status),
                      style: TextStyle(
                        color: _getStatusColor(widget.job.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    widget.job.status == AppConstants.jobStatusPending
                        ? Icons.location_searching
                        : Icons.location_on,
                    size: 16,
                    color: widget.job.status == AppConstants.jobStatusPending
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _isLoadingAddress
                        ? const Text(
                            'Obteniendo ubicación...',
                            style: TextStyle(fontSize: 12),
                          )
                        : Text(
                            _displayAddress,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: widget.job.status == AppConstants.jobStatusPending
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                  ),
                  if (widget.job.status == AppConstants.jobStatusPending)
                    Tooltip(
                      message: 'Ubicación aproximada. Verás la ubicación exacta al aceptar el trabajo',
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(widget.job.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

