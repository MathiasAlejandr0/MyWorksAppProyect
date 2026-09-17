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
      context.push(AppConstants.routeWorkerProfileManage);
    } else if (item.contains('portafolio')) {
      context.push(AppConstants.routeWorkerProfileManage);
    } else if (item.contains('Tarifas') || item.contains('precio')) {
      context.push(AppConstants.routeWorkerPricingSetup);
    } else if (item.contains('zona')) {
      context.push(AppConstants.routeWorkerProfileManage);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.white : AppColors.brandNavy;
    final muted = isDark
        ? AppColors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkElevated : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.brandOrange.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandOrange.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.brandOrange.withValues(alpha: 0.18),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: AppColors.brandOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Completa tu perfil (${status.completionPercentage}%)',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: muted),
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: status.completionPercentage / 100,
                minHeight: 6,
                color: AppColors.brandOrange,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.brandOrangeSoft,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Para aparecer en búsquedas y recibir trabajos:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
            const SizedBox(height: 4),
            ...status.missingItems.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.radio_button_unchecked,
                  size: 20,
                  color: AppColors.brandOrange.withValues(alpha: 0.85),
                ),
                title: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: muted, size: 18),
                onTap: () => _goToStep(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
