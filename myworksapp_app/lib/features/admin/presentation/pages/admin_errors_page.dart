import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/models/abuse_event_model.dart';
import '../../../../core/database/models/app_error_log_model.dart';
import '../../../../core/database/models/pending_action_model.dart';
import '../../../../core/database/repositories/admin_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../widgets/admin_search_field.dart';

class AdminErrorsPage extends ConsumerStatefulWidget {
  const AdminErrorsPage({super.key});

  @override
  ConsumerState<AdminErrorsPage> createState() => _AdminErrorsPageState();
}

class _AdminErrorsPageState extends ConsumerState<AdminErrorsPage>
    with SingleTickerProviderStateMixin {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  late final TabController _tabs;

  List<AppErrorLogModel> _errors = [];
  List<PendingActionModel> _pending = [];
  List<AbuseEventModel> _abuse = [];
  bool _loading = true;
  String _search = '';
  String? _errorStatus;
  String? _syncStatus;
  bool _abuseUnresolvedOnly = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.listErrorLogs(
          status: _errorStatus,
          search: _search.isEmpty ? null : _search,
        ),
        _repo.listPendingActions(
          status: _syncStatus,
          search: _search.isEmpty ? null : _search,
        ),
        _repo.listAbuseEvents(
          unresolvedOnly: _abuseUnresolvedOnly,
          search: _search.isEmpty ? null : _search,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _errors = results[0] as List<AppErrorLogModel>;
        _pending = results[1] as List<PendingActionModel>;
        _abuse = results[2] as List<AbuseEventModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resolveError(AppErrorLogModel log, String status) async {
    await _repo.updateErrorLogStatus(log.id, status);
    await _load();
  }

  Future<void> _resolveAbuse(AbuseEventModel event) async {
    await _repo.resolveAbuseEvent(event.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Errores e incidencias'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Errores (${_errors.length})'),
            Tab(text: 'Sync (${_pending.length})'),
            Tab(text: 'Abuso (${_abuse.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Buscar errores, sync o abuso…',
            onSearch: (q) {
              _search = q;
              _load();
            },
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _ErrorLogsTab(
                        logs: _errors,
                        errorStatus: _errorStatus,
                        onStatusFilter: (s) {
                          _errorStatus = s;
                          _load();
                        },
                        onRefresh: _load,
                        onUpdateStatus: _resolveError,
                      ),
                      _PendingTab(
                        actions: _pending,
                        syncStatus: _syncStatus,
                        onStatusFilter: (s) {
                          _syncStatus = s;
                          _load();
                        },
                        onRefresh: _load,
                      ),
                      _AbuseTab(
                        events: _abuse,
                        unresolvedOnly: _abuseUnresolvedOnly,
                        onUnresolvedFilter: (v) {
                          _abuseUnresolvedOnly = v;
                          _load();
                        },
                        onRefresh: _load,
                        onResolve: _resolveAbuse,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ErrorLogsTab extends StatelessWidget {
  const _ErrorLogsTab({
    required this.logs,
    required this.errorStatus,
    required this.onStatusFilter,
    required this.onRefresh,
    required this.onUpdateStatus,
  });

  final List<AppErrorLogModel> logs;
  final String? errorStatus;
  final ValueChanged<String?> onStatusFilter;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AppErrorLogModel, String) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return ListView(
        children: [
          _StatusChips(
            labels: const ['Todos', 'Nuevos', 'Reconocidos', 'Resueltos'],
            values: const [null, 'new', 'acknowledged', 'resolved'],
            selected: errorStatus,
            onSelected: onStatusFilter,
          ),
          const Center(child: Text('Sin errores registrados')),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: logs.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StatusChips(
              labels: const ['Todos', 'Nuevos', 'Reconocidos', 'Resueltos'],
              values: const [null, 'new', 'acknowledged', 'resolved'],
              selected: errorStatus,
              onSelected: onStatusFilter,
            );
          }
          final log = logs[index - 1];
          return Card(
            child: ExpansionTile(
              leading: Icon(
                Icons.bug_report_outlined,
                color: log.status == 'new'
                    ? AppColors.brandOrange
                    : AppColors.success,
              ),
              title: Text(
                log.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${log.errorType} · ${log.status} · ${log.platform ?? '—'}',
              ),
              children: [
                if (log.stackTrace != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SelectableText(
                      log.stackTrace!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (log.status == 'new')
                      TextButton(
                        onPressed: () => onUpdateStatus(log, 'acknowledged'),
                        child: const Text('Reconocer'),
                      ),
                    TextButton(
                      onPressed: () => onUpdateStatus(log, 'resolved'),
                      child: const Text('Resolver'),
                    ),
                    TextButton(
                      onPressed: () => onUpdateStatus(log, 'ignored'),
                      child: const Text('Ignorar'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  const _PendingTab({
    required this.actions,
    required this.syncStatus,
    required this.onStatusFilter,
    required this.onRefresh,
  });

  final List<PendingActionModel> actions;
  final String? syncStatus;
  final ValueChanged<String?> onStatusFilter;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return ListView(
        children: [
          _StatusChips(
            labels: const ['Todos', 'Fallidos', 'Pendientes'],
            values: const [null, 'failed', 'pending_sync'],
            selected: syncStatus,
            onSelected: onStatusFilter,
          ),
          const Center(child: Text('Sin acciones pendientes')),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: actions.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StatusChips(
              labels: const ['Todos', 'Fallidos', 'Pendientes'],
              values: const [null, 'failed', 'pending_sync'],
              selected: syncStatus,
              onSelected: onStatusFilter,
            );
          }
          final a = actions[index - 1];
          return Card(
            child: ListTile(
              leading: Icon(
                a.status == 'failed'
                    ? Icons.sync_problem
                    : Icons.sync,
                color: a.status == 'failed'
                    ? AppColors.brandOrange
                    : AppColors.warning,
              ),
              title: Text('${a.actionType} · ${a.entityType}'),
              subtitle: Text(
                '${a.status}\n${a.errorMessage ?? a.entityId ?? ''}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class _AbuseTab extends StatelessWidget {
  const _AbuseTab({
    required this.events,
    required this.unresolvedOnly,
    required this.onUnresolvedFilter,
    required this.onRefresh,
    required this.onResolve,
  });

  final List<AbuseEventModel> events;
  final bool unresolvedOnly;
  final ValueChanged<bool> onUnresolvedFilter;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AbuseEventModel) onResolve;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return ListView(
        children: [
          FilterChip(
            label: const Text('Solo sin resolver'),
            selected: unresolvedOnly,
            onSelected: onUnresolvedFilter,
          ),
          const Center(child: Text('Sin eventos de abuso')),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: events.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilterChip(
                label: const Text('Solo sin resolver'),
                selected: unresolvedOnly,
                onSelected: onUnresolvedFilter,
              ),
            );
          }
          final e = events[index - 1];
          return Card(
            child: ListTile(
              leading: Icon(
                Icons.shield_outlined,
                color: e.isResolved ? AppColors.success : AppColors.brandOrange,
              ),
              title: Text(e.abuseType),
              subtitle: Text(
                'Usuario ${e.userId.substring(0, 8)}… · '
                '×${e.count}\n${e.actionTaken ?? 'Sin acción'}',
              ),
              isThreeLine: true,
              trailing: e.isResolved
                  ? null
                  : TextButton(
                      onPressed: () => onResolve(e),
                      child: const Text('Resolver'),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({
    required this.labels,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final List<String?> values;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        children: List.generate(labels.length, (i) {
          final value = values[i];
          return FilterChip(
            label: Text(labels[i]),
            selected: selected == value,
            onSelected: (_) => onSelected(value),
          );
        }),
      ),
    );
  }
}
