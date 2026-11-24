import 'package:flutter/material.dart';
import 'package:myworksapp/core/theme/app_colors.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/repositories/notification_repository.dart';
import '../../../../core/database/supabase_db.dart';
import '../../domain/notification_groups.dart';
import '../../../../core/database/models/notification_model.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/loading_skeleton.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/error_state_widget.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  List<NotificationModel> _notifications = [];
  Map<String, JobNoticeLabel> _jobLabels = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _notifications = [];
          _isLoading = false;
          _error = 'Inicia sesión para ver tus notificaciones.';
        });
        return;
      }
      final notifications =
          await _notificationRepository.getNotificationsByUserId(user.id);
      final labels = await _loadJobLabels(notifications);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _jobLabels = labels;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  Future<Map<String, JobNoticeLabel>> _loadJobLabels(
    List<NotificationModel> notifications,
  ) async {
    final ids = notifications
        .map((item) => item.relatedId?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return {};
    try {
      final rows = await supabase
          .from('trabajos')
          .select('id, descripcion, direccion, servicios(nombre)')
          .inFilter('id', ids);
      return _labelsFromRows(rows);
    } catch (_) {
      try {
        final rows = await supabase
            .from('trabajos')
            .select('id, descripcion, direccion')
            .inFilter('id', ids);
        return _labelsFromRows(rows);
      } catch (_) {
        return {};
      }
    }
  }

  Map<String, JobNoticeLabel> _labelsFromRows(Object? rows) {
    final labels = <String, JobNoticeLabel>{};
    if (rows is! Iterable) return labels;
    for (final row in rows) {
      if (row is! Map) continue;
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      labels[id] = labelForJob(
        serviceName: serviceNameFromEmbed(row['servicios']),
        description: row['descripcion']?.toString(),
        address: row['direccion']?.toString(),
      );
    }
    return labels;
  }

  Future<void> _openFolder(NotificationFolder folder) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _NotificationFolderPage(
          folder: folder,
          onOpenNotice: _handleNotificationTap,
        ),
      ),
    );
    if (mounted) await _loadNotifications();
  }

  Future<void> _markAsRead(String id) async {
    await _notificationRepository.markAsRead(id);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user != null) {
      await _notificationRepository.markAllAsRead(user.id);
      await _loadNotifications();
    }
  }

  void _handleNotificationTap(
    NotificationModel notification, [
    BuildContext? from,
  ]) {
    _markAsRead(notification.id);

    if (notification.relatedId == null) return;
    final nav = from ?? context;
    if (!nav.mounted) return;

    if (notification.type == 'new_message') {
      nav.push('${AppConstants.routeChat}/${notification.relatedId}');
      return;
    }
    if (_opensJob(notification.type)) {
      nav.push('${AppConstants.routeJobDetail}/${notification.relatedId}');
    }
  }

  bool _opensJob(String type) {
    return type == 'new_job' ||
        type == 'new_job_quote' ||
        type == 'pago_reembolsado' ||
        type == 'quote_received' ||
        type == 'dispute_opened' ||
        type == 'worker_unavailable' ||
        type.startsWith('job_');
  }

  bool get _hasUnread => _notifications.any((n) => !n.isRead);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppGradientAppBar(
        title: Text(
          'Notificaciones',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 5,
              itemBuilder: (context, index) => const ListItemSkeleton(),
            )
          : _error != null
              ? ErrorStateWidget(
                  title: 'No se pudieron cargar las notificaciones',
                  message: _error,
                  onRetry: _loadNotifications,
                )
              : _notifications.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.notifications_none,
                      title: 'No hay notificaciones',
                      message:
                          'Las notificaciones aparecerán aquí cuando haya actualizaciones',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_hasUnread)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xs,
                                AppSpacing.sm,
                                0,
                              ),
                              child: TextButton(
                                onPressed: _markAllAsRead,
                                child: const Text('Marcar todas como leídas'),
                              ),
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView(
                              padding: LayoutUtils.scrollPadding(context, top: 8),
                              children: [
                                for (final folder in groupNotificationsByJob(
                                  _notifications,
                                  jobLabels: _jobLabels,
                                ))
                                  _NoticeFolder(
                                    folder: folder,
                                    onOpen: () => _openFolder(folder),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _NoticeFolder extends StatelessWidget {
  const _NoticeFolder({required this.folder, required this.onOpen});

  final NotificationFolder folder;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final latest = folder.items.first;
    final unread = folder.unreadCount;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandOrange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: AppColors.brandOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (folder.detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        folder.detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${_avisosLabel(folder.items.length)} · ${latest.title} · ${formatNoticeAge(folder.latestAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationFolderPage extends StatefulWidget {
  const _NotificationFolderPage({
    required this.folder,
    required this.onOpenNotice,
  });

  final NotificationFolder folder;
  final void Function(NotificationModel notification, BuildContext from) onOpenNotice;

  @override
  State<_NotificationFolderPage> createState() => _NotificationFolderPageState();
}

class _NotificationFolderPageState extends State<_NotificationFolderPage> {
  final Set<String> _openedIds = {};

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final brightness = Theme.of(context).brightness;
    final muted = AppColors.onCanvasMuted(brightness);
    final isJob = folder.key != generalNoticesKey;

    return Scaffold(
      appBar: AppGradientAppBar(
        title: Text(
          folder.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (isJob)
            TextButton(
              onPressed: () => context.push(
                '${AppConstants.routeJobDetail}/${folder.key}',
              ),
              child: const Text('Ver trabajo'),
            ),
        ],
      ),
      body: ListView(
        padding: LayoutUtils.scrollPadding(context, top: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              folder.detail == null
                  ? _avisosLabel(folder.items.length)
                  : '${folder.detail} · ${_avisosLabel(folder.items.length)}',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ),
          for (final notification in folder.items)
            _NotificationItem(
              notification: notification,
              isRead: notification.isRead || _openedIds.contains(notification.id),
              onTap: () {
                setState(() => _openedIds.add(notification.id));
                widget.onOpenNotice(notification, context);
              },
            ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final bool? isRead;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    this.isRead,
  });

  bool get _read => isRead ?? notification.isRead;

  IconData _getIcon() {
    switch (notification.type) {
      case 'job_accepted':
        return Icons.check_circle;
      case 'job_rejected':
      case 'job_cancelled':
        return Icons.cancel;
      case 'job_completed':
        return Icons.work;
      case 'new_job':
        return Icons.add_circle;
      case 'job_rescheduled':
        return Icons.event_repeat;
      case 'new_message':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'job_accepted':
      case 'job_completed':
        return AppColors.success;
      case 'job_rejected':
      case 'job_cancelled':
        return AppColors.error;
      case 'new_job':
      case 'job_rescheduled':
        return AppColors.brandOrange;
      case 'new_message':
        return AppColors.brandOrangeDark;
      default:
        return AppColors.grayMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _read
          ? null
          : Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor().withValues(alpha: 0.2),
          child: Icon(
            _getIcon(),
            color: _getColor(),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: _read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              formatNoticeAge(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: _read
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}

String _avisosLabel(int count) => count == 1 ? '1 aviso' : '$count avisos';

String formatNoticeAge(DateTime date, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(date);
  if (difference.inMinutes < 1) return 'Ahora';
  if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
  if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
  if (difference.inDays < 7) {
    final days = difference.inDays;
    return days == 1 ? 'Hace 1 día' : 'Hace $days días';
  }
  return '${date.day}/${date.month}/${date.year}';
}
