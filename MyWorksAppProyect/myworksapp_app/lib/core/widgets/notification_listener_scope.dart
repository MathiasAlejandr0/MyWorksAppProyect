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

    final palette = inAppNoticePalette(Theme.of(context).brightness);

    return Stack(
      children: [
        widget.child,
        if (_latest != null)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Material(
              elevation: 8,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              color: palette.background,
              child: InkWell(
                onTap: () => _openNotification(_latest!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border, width: 1.5),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: palette.icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _latest!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: palette.title,
                              ),
                            ),
                            if (_latest!.body.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _latest!.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.body,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        icon: Icon(Icons.close, size: 20, color: palette.title),
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

/// Cartel invertido respecto al tema: en oscuro es claro y en claro es oscuro,
/// para que se separe del fondo y el texto se lea en los dos.
class InAppNoticePalette {
  const InAppNoticePalette({
    required this.background,
    required this.title,
    required this.body,
    required this.icon,
    required this.border,
  });

  final Color background;
  final Color title;
  final Color body;
  final Color icon;
  final Color border;
}

InAppNoticePalette inAppNoticePalette(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const InAppNoticePalette(
      background: Color(0xFFF7F5F2),
      title: Color(0xFF12141A),
      body: Color(0xFF3A4150),
      icon: AppColors.brandOrangeDark,
      border: Color(0xFF00205B),
    );
  }
  return const InAppNoticePalette(
    background: Color(0xFF00205B),
    title: Color(0xFFF7F8FA),
    body: Color(0xFFE4E7EE),
    icon: AppColors.brandOrange,
    border: Color(0xFFFF5E03),
  );
}
