import 'package:flutter/material.dart';
import 'package:myworksapp/core/theme/app_colors.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/providers/repository_providers.dart';
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
  static const _pageSize = 20;

  final _jobs = <JobModel>[];
  final _scroll = ScrollController();
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 400) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(jobRepositoryProvider).getJobsPage(
            userId: user.id,
            asWorker: user.role == AppConstants.roleWorker,
            offset: _jobs.length,
            limit: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _jobs.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _reload() async {
    setState(() {
      _jobs.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

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
      appBar: const AppGradientAppBar(
        title: Text('Historial de Trabajos'),
      ),
      body: _buildBody(user.role == AppConstants.roleWorker),
    );
  }

  Widget _buildBody(bool isWorker) {
    if (_jobs.isEmpty && _loading) return const LoadingWidget();

    if (_jobs.isEmpty && _error != null) {
      return ErrorStateWidget(
        title: 'Error al cargar historial',
        message: ErrorHandler.getErrorMessage(_error),
        actionLabel: 'Reintentar',
        onRetry: _reload,
      );
    }

    if (_jobs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.history,
        title: 'No hay trabajos',
        message: isWorker
            ? 'Tus trabajos asignados aparecerán aquí cuando aceptes solicitudes.'
            : 'Tu historial de trabajos aparecerá aquí cuando solicites servicios',
      );
    }

    final showFooter = _hasMore || _error != null;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _jobs.length) return _buildFooter();
          final job = _jobs[index];
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
      ),
    );
  }

  Widget _buildFooter() {
    if (_error != null) {
      return Center(
        child: TextButton(
          onPressed: _loadMore,
          child: const Text('No se pudieron cargar más. Reintentar'),
        ),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Center(
      child: TextButton(
        onPressed: _loadMore,
        child: const Text('Cargar más'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return AppColors.warning;
      case AppConstants.jobStatusAccepted:
        return AppColors.brandOrange;
      case AppConstants.jobStatusInProgress:
        return AppColors.brandOrangeDark;
      case AppConstants.jobStatusCompleted:
        return AppColors.success;
      case AppConstants.jobStatusCancelled:
        return AppColors.error;
      default:
        return AppColors.grayMedium;
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
