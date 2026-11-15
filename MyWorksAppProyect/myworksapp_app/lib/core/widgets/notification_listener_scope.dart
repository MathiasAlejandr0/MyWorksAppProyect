import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/models/notification_model.dart';
import '../services/notification_realtime_service.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Muestra un banner in-app cuando llega una notificación (Realtime).
class NotificationListenerScope extends ConsumerStatefulWidget {
  const NotificationListenerScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationListenerScope> createState() =>
      _NotificationListenerScopeState();
}

class _NotificationListenerScopeState
    extends ConsumerState<NotificationListenerScope> {
  StreamSubscription<NotificationModel>? _subscription;
  NotificationModel? _latest;

  @override
  void initState() {
    super.initState();
    _subscription = NotificationRealtimeService.instance.onIncoming.listen(
      _onIncoming,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onIncoming(NotificationModel notification) {
    if (!mounted) return;
    setState(() => _latest = notification);
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _latest?.id == notification.id) {
        setState(() => _latest = null);
      }
    });
  }

  void _openNotification(NotificationModel n) {
    setState(() => _latest = null);
    if (n.relatedId != null &&
        (n.type.startsWith('job') || n.type.contains('change_order'))) {
      context.push('${AppConstants.routeJobDetail}/${n.relatedId}');
      return;
    }
    context.push(AppConstants.routeNotifications);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider.select((s) => s.user?.id), (prev, next) {
      if (next == null) {
        NotificationRealtimeService.instance.unsubscribe();
      } else if (next != prev) {
        NotificationRealtimeService.instance.subscribe(next);
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_latest != null)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.white,
              child: InkWell(
                onTap: () => _openNotification(_latest!),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: AppColors.brandOrange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _latest!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _latest!.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _latest = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
