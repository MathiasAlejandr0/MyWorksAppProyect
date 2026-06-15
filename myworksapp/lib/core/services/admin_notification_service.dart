import 'package:uuid/uuid.dart';

import '../database/models/notification_model.dart';
import '../database/repositories/notification_repository.dart';
import '../utils/app_logger.dart';

/// Notificaciones in-app disparadas por acciones del panel admin.
class AdminNotificationService {
  static final AdminNotificationService instance =
      AdminNotificationService._();
  AdminNotificationService._();

  final NotificationRepository _repo = NotificationRepository();

  Future<void> _send({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    try {
      await _repo.createNotification(
        NotificationModel(
          id: const Uuid().v4(),
          userId: userId,
          type: type,
          title: title,
          body: body,
          relatedId: relatedId,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.e('Error enviando notificación admin', e);
    }
  }

  Future<void> notifyReportStatusChange({
    required String reporterId,
    required String reportedUserId,
    required String status,
    required String reportId,
    String? reason,
  }) async {
    final reasonLabel = reason ?? 'reclamo';

    switch (status) {
      case 'reviewed':
        await _send(
          userId: reporterId,
          type: 'admin_report_reviewed',
          title: 'Reclamo en revisión',
          body: 'Tu reclamo por "$reasonLabel" está siendo revisado por el equipo.',
          relatedId: reportId,
        );
        break;
      case 'resolved':
        await _send(
          userId: reporterId,
          type: 'admin_report_resolved',
          title: 'Reclamo resuelto',
          body: 'Tu reclamo por "$reasonLabel" fue resuelto por el administrador.',
          relatedId: reportId,
        );
        await _send(
          userId: reportedUserId,
          type: 'admin_report_resolved',
          title: 'Reclamo resuelto',
          body: 'Un reclamo en tu contra fue revisado y cerrado por el administrador.',
          relatedId: reportId,
        );
        break;
      case 'dismissed':
        await _send(
          userId: reporterId,
          type: 'admin_report_dismissed',
          title: 'Reclamo descartado',
          body: 'Tu reclamo por "$reasonLabel" fue descartado tras la revisión.',
          relatedId: reportId,
        );
        break;
    }
  }

  Future<void> notifyDisputeUnderReview({
    required String userId,
    required String? workerId,
    required String jobId,
    required String disputeId,
  }) async {
    const body =
        'La disputa de tu trabajo está siendo revisada por el administrador.';
    await _send(
      userId: userId,
      type: 'admin_dispute_review',
      title: 'Disputa en revisión',
      body: body,
      relatedId: disputeId,
    );
    if (workerId != null) {
      await _send(
        userId: workerId,
        type: 'admin_dispute_review',
        title: 'Disputa en revisión',
        body: body,
        relatedId: disputeId,
      );
    }
  }

  Future<void> notifyDisputeResolved({
    required String userId,
    required String? workerId,
    required String disputeId,
    required String resolution,
  }) async {
    final body = resolution.isEmpty
        ? 'La disputa fue resuelta por el administrador.'
        : 'Resolución: $resolution';

    await _send(
      userId: userId,
      type: 'admin_dispute_resolved',
      title: 'Disputa resuelta',
      body: body,
      relatedId: disputeId,
    );
    if (workerId != null) {
      await _send(
        userId: workerId,
        type: 'admin_dispute_resolved',
        title: 'Disputa resuelta',
        body: body,
        relatedId: disputeId,
      );
    }
  }
}
