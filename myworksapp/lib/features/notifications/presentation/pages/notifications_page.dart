import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/repositories/notification_repository.dart';
import '../../../../core/database/models/notification_model.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../../core/widgets/design_system/loading_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/constants.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      if (user != null) {
        final notifications = await _notificationRepository.getNotificationsByUserId(user.id);
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

  void _handleNotificationTap(NotificationModel notification) {
    _markAsRead(notification.id);

    if (notification.relatedId == null) return;

    switch (notification.type) {
      case 'job_accepted':
      case 'job_rejected':
      case 'job_completed':
      case 'job_cancelled':
      case 'new_job':
        context.push('${AppConstants.routeJobDetail}/${notification.relatedId}');
        break;
      case 'new_message':
        context.push('${AppConstants.routeChat}/${notification.relatedId}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (!_isLoading && _notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Marcar todas como leídas'),
            ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const ListItemSkeleton(),
            )
          : _notifications.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.notifications_none,
                  title: 'No hay notificaciones',
                  message: 'Las notificaciones aparecerán aquí cuando haya actualizaciones',
                )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _NotificationItem(
                    notification: notification,
                    onTap: () => _handleNotificationTap(notification),
                  );
                },
              ),
            ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

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
        return Colors.green;
      case 'job_rejected':
      case 'job_cancelled':
        return Colors.red;
      case 'new_job':
        return Colors.blue;
      case 'new_message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: notification.isRead
          ? null
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.isRead
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

