import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/models/worker_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';

/// Sugiere otros profesionales cuando el elegido no está disponible.
class WorkerUnavailableDialog extends StatefulWidget {
  const WorkerUnavailableDialog({
    super.key,
    required this.workerName,
    required this.alternatives,
    required this.serviceId,
  });

  final String workerName;
  final List<WorkerModel> alternatives;
  final String serviceId;

  static Future<void> show(
    BuildContext context, {
    required String workerName,
    required List<WorkerModel> alternatives,
    required String serviceId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => WorkerUnavailableDialog(
        workerName: workerName,
        alternatives: alternatives,
        serviceId: serviceId,
      ),
    );
  }

  @override
  State<WorkerUnavailableDialog> createState() => _WorkerUnavailableDialogState();
}

class _WorkerUnavailableDialogState extends State<WorkerUnavailableDialog> {
  final _userRepository = UserRepository();
  final Map<String, UserModel?> _users = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    for (final worker in widget.alternatives) {
      _users[worker.userId] = await _userRepository.getUserById(worker.userId);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.person_off_outlined, color: AppColors.brandOrange, size: 40),
      title: const Text('Profesional no disponible'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.workerName} no puede tomar tu solicitud en este momento.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.alternatives.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Otros profesionales disponibles:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              ...widget.alternatives.map((worker) {
                final user = _users[worker.userId];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ProfileAvatarView(
                    displayName: user?.name ?? worker.profession,
                    photoPath: user?.profilePhotoPath,
                    radius: 20,
                    onDarkBackground: false,
                  ),
                  title: Text(user?.name ?? worker.profession),
                  subtitle: Text(worker.profession),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      '${AppConstants.routeWorkerDetail}/${worker.userId}',
                      extra: {'serviceId': widget.serviceId},
                    );
                  },
                );
              }),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Por ahora no hay otros profesionales disponibles para este servicio.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grayMedium,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push(
              AppConstants.routeWorkerList,
              extra: {'serviceId': widget.serviceId},
            );
          },
          child: const Text('Ver todos'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(backgroundColor: AppColors.brandOrange),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
