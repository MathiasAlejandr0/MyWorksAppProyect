import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/santiago_time.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/job_history_cards.dart';

class JobHistoryPage extends ConsumerStatefulWidget {
  const JobHistoryPage({super.key});

  @override
  ConsumerState<JobHistoryPage> createState() => _JobHistoryPageState();
}

class _JobHistoryPageState extends ConsumerState<JobHistoryPage> {
  static const _pageSize = 20;

  final _live = <JobModel>[];
  final _past = <JobModel>[];
  final _scroll = ScrollController();
  bool _loading = false;
  bool _hasMore = true;
  bool _liveLoaded = false;
  int _request = 0;
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
    final request = _request;
    final asWorker = user.role == AppConstants.roleWorker;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(jobRepositoryProvider);
      if (!_liveLoaded) {
        final live = await repo.getHistoryLiveJobs(
          userId: user.id,
          asWorker: asWorker,
        );
        if (!mounted || request != _request) return;
        setState(() {
          _live
            ..clear()
            ..addAll(live);
          _liveLoaded = true;
        });
      }
      final page = await repo.getHistoryPastPage(
        userId: user.id,
        asWorker: asWorker,
        offset: _past.length,
        limit: _pageSize,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _past.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _reload() async {
    _request += 1;
    setState(() {
      _live.clear();
      _past.clear();
      _liveLoaded = false;
      _hasMore = true;
      _loading = false;
      _error = null;
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
    final empty = _live.isEmpty && _past.isEmpty;
    if (empty && _loading) return const LoadingWidget();

    if (empty && _error != null) {
      return ErrorStateWidget(
        title: 'Error al cargar historial',
        message: ErrorHandler.getErrorMessage(_error),
        actionLabel: 'Reintentar',
        onRetry: _reload,
      );
    }

    if (empty) {
      return EmptyStateWidget(
        icon: Icons.history,
        title: 'No hay trabajos',
        message: isWorker
            ? 'Tus trabajos asignados aparecerán aquí cuando aceptes solicitudes.'
            : 'Tu historial de trabajos aparecerá aquí cuando solicites servicios',
      );
    }

    final entries = _entries();
    final showFooter = _hasMore || _error != null;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: entries.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= entries.length) return _buildFooter();
          final entry = entries[index];
          if (entry.header != null) return _sectionLabel(entry.header!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _cardFor(entry.job!),
          );
        },
      ),
    );
  }

  /// Los trabajos con pago retenido se piden aparte, así quedan arriba
  /// aunque haya pedidos cerrados más nuevos.
  List<_HistoryEntry> _entries() {
    final entries = <_HistoryEntry>[];
    if (_live.isNotEmpty) {
      entries.add(const _HistoryEntry.header('Pago retenido'));
      for (final job in _live) {
        entries.add(_HistoryEntry.job(job));
      }
    }
    if (_past.isNotEmpty) {
      if (_live.isNotEmpty) {
        entries.add(const _HistoryEntry.header('Anteriores'));
      }
      for (final job in _past) {
        entries.add(_HistoryEntry.job(job));
      }
    }
    return entries;
  }

  Widget _sectionLabel(String title) {
    final live = title == 'Pago retenido';
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: live ? 0 : 8),
      child: Text(
        title,
        style: TextStyle(
          color: live
              ? AppColors.brandOrange
              : AppColors.onCanvasMuted(Theme.of(context).brightness),
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _cardFor(JobModel job) {
    final title = (job.description ?? '').trim().isEmpty
        ? 'Sin descripción'
        : job.description!.trim();
    final dateLabel = _formatDate(job.createdAt);
    void open() => context.push('${AppConstants.routeJobDetail}/${job.id}');

    if (jobHistoryIsLive(job.status)) {
      return JobHistoryLiveCard(
        title: title,
        address: job.address,
        dateLabel: dateLabel,
        status: job.status,
        onTap: open,
      );
    }
    if (job.status == AppConstants.jobStatusCompleted) {
      return JobHistoryCompletedCard(
        title: title,
        address: job.address,
        dateLabel: dateLabel,
        paymentStatus: job.paymentStatus,
        onTap: open,
      );
    }
    return JobHistoryClosedCard(
      title: title,
      address: job.address,
      dateLabel: dateLabel,
      status: job.status,
      onTap: open,
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

  String _formatDate(DateTime date) {
    final local = SantiagoTime.wall(date);
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _HistoryEntry {
  const _HistoryEntry.header(this.header) : job = null;
  const _HistoryEntry.job(this.job) : header = null;

  final String? header;
  final JobModel? job;
}
