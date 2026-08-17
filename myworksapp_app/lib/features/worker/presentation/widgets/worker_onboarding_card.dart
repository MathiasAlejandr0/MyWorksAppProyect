import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/worker_onboarding_checklist_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';

class WorkerOnboardingCard extends StatefulWidget {
  const WorkerOnboardingCard({
    super.key,
    required this.workerId,
    this.onCompleted,
  });

  final String workerId;
  final VoidCallback? onCompleted;

  @override
  State<WorkerOnboardingCard> createState() => _WorkerOnboardingCardState();
}

class _WorkerOnboardingCardState extends State<WorkerOnboardingCard> {
  WorkerOnboardingStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await WorkerOnboardingChecklistService.instance
        .checkStatus(widget.workerId);
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
    if (status.isComplete) {
      widget.onCompleted?.call();
    }
  }

  void _goToStep(String item) {
    if (item.contains('foto')) {
      context.push(AppConstants.routeWorkerProfile);
    } else if (item.contains('Descripción')) {
      context.push(AppConstants.routeWorkerProfile);
    } else if (item.contains('portafolio')) {
      context.push(AppConstants.routeWorkerProfile);
    } else if (item.contains('Tarifas') || item.contains('precio')) {
      context.push(AppConstants.routeWorkerPricingSetup);
    } else if (item.contains('zona')) {
      context.push(AppConstants.routeWorkerProfile);
    } else if (item.contains('Servicio')) {
      context.push(AppConstants.routeWorkerRegister);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 4,
        child: LinearProgressIndicator(color: AppColors.brandOrange),
      );
    }

    final status = _status;
    if (status == null || status.isComplete) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Card(
        color: AppColors.brandOrangeSoft,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.checklist, color: AppColors.brandOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Completa tu perfil (${status.completionPercentage}%)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: status.completionPercentage / 100,
                color: AppColors.brandOrange,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                'Para aparecer en búsquedas y recibir trabajos:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ...status.missingItems.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.radio_button_unchecked, size: 20),
                  title: Text(item),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _goToStep(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
