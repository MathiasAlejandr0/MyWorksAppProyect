import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class JobHistoryPage extends ConsumerStatefulWidget {
  const JobHistoryPage({super.key});

  @override
  ConsumerState<JobHistoryPage> createState() => _JobHistoryPageState();
}

class _JobHistoryPageState extends ConsumerState<JobHistoryPage> {
  final JobRepository _jobRepository = JobRepository();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        appBar: null,
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Historial de Trabajos'),
      ),
      body: FutureBuilder<List<JobModel>>(
        future: _jobRepository.getJobsByUserId(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              title: 'Error al cargar historial',
              message: ErrorHandler.getErrorMessage(snapshot.error),
              actionLabel: 'Reintentar',
              onRetry: () {
                setState(() {});
              },
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.history,
              title: 'No hay trabajos',
              message: 'Tu historial de trabajos aparecerá aquí cuando solicites servicios',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    job.description ?? 'Sin descripción',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(job.address),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(job.createdAt)} - ${_getStatusText(job.status)}',
                      ),
                    ],
                  ),
                  trailing: Icon(
                    _getStatusIcon(job.status),
                    color: _getStatusColor(job.status),
                  ),
                  onTap: () {
                    context.push('${AppConstants.routeJobDetail}/${job.id}');
                  },
                ),
              );
            },
          );
        },
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


