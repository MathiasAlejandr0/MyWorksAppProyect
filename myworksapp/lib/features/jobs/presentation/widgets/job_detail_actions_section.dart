import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../utils/job_detail_helpers.dart';

class JobDetailActionsSection extends StatelessWidget {
  final String jobId;
  final JobModel job;
  final bool isWorker;
  final bool isOwner;
  final Map<String, bool> canTransition;
  final VoidCallback onGoToDashboard;
  final Future<void> Function() onCancelJob;
  final VoidCallback onAcceptJob;
  final Future<void> Function() onRejectJob;
  final VoidCallback onStartJob;
  final VoidCallback onRequestOvertimeHours;
  final VoidCallback onCompleteJob;

  const JobDetailActionsSection({
    super.key,
    required this.jobId,
    required this.job,
    required this.isWorker,
    required this.isOwner,
    required this.canTransition,
    required this.onGoToDashboard,
    required this.onCancelJob,
    required this.onAcceptJob,
    required this.onRejectJob,
    required this.onStartJob,
    required this.onRequestOvertimeHours,
    required this.onCompleteJob,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOwner) ...[
          if (!isWorker &&
              job.status == AppConstants.jobStatusPending &&
              canTransition[AppConstants.jobStatusCancelled] == true)
            OutlinedButton(
              onPressed: onCancelJob,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancelar Solicitud'),
            ),
          if (isWorker &&
              job.status == AppConstants.jobStatusPending &&
              canTransition[AppConstants.jobStatusAccepted] == true) ...[
            ElevatedButton(
              onPressed: onAcceptJob,
              child: const Text('Aceptar Trabajo'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRejectJob,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Rechazar'),
            ),
          ],
          if (isWorker &&
              job.status == AppConstants.jobStatusAccepted &&
              canTransition[AppConstants.jobStatusInProgress] == true)
            ElevatedButton(
              onPressed: onStartJob,
              child: const Text('Iniciar Trabajo'),
            ),
          if (isWorker && job.status == AppConstants.jobStatusInProgress) ...[
            if (job.pricingMode == PricingConstants.modeHourlyBlock) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRequestOvertimeHours,
                icon: const Icon(Icons.more_time),
                label: const Text('Solicitar horas extra'),
              ),
            ],
            const SizedBox(height: 8),
          ],
          if (isWorker &&
              job.status == AppConstants.jobStatusInProgress &&
              (canTransition[AppConstants.jobStatusCompleted] == true ||
                  canTransition[PricingConstants.jobAwaitingClientApproval] ==
                      true)) ...[
            ElevatedButton(
              onPressed: onCompleteJob,
              child: Text(
                JobDetailHelpers.isWorkerTierInvitation(job)
                    ? 'Finalizar y enviar evidencia'
                    : 'Finalizar Trabajo',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                context.push('${AppConstants.routeJobPhotos}/$jobId');
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Subir evidencia'),
            ),
          ],
          if (isWorker && job.status == PricingConstants.jobAwaitingPayment)
            Text(
              'El trabajo se confirmará cuando el cliente complete el pago.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayMedium,
                  ),
            ),
          if (!isWorker && job.status == AppConstants.jobStatusCompleted)
            FutureBuilder<bool>(
              future: DisputeService.instance.canRateJob(jobId),
              builder: (context, snapshot) {
                final canRate = snapshot.data ?? true;
                if (!canRate) {
                  return const Text(
                    'Calificación bloqueada por disputa abierta.',
                    style: TextStyle(color: AppColors.warning),
                  );
                }
                return ElevatedButton(
                  onPressed: () {
                    context.push('${AppConstants.routeRating}/$jobId');
                  },
                  child: const Text('Calificar Trabajo'),
                );
              },
            ),
          if ((job.status == AppConstants.jobStatusAccepted ||
                  job.status == AppConstants.jobStatusInProgress) &&
              isOwner) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                context.push('${AppConstants.routeChat}/$jobId');
              },
              icon: const Icon(Icons.chat),
              label: const Text('Abrir Chat'),
            ),
          ],
          if (isOwner &&
              job.status != AppConstants.jobStatusPending &&
              job.status != AppConstants.jobStatusInProgress) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                context.push('${AppConstants.routeJobPhotos}/$jobId');
              },
              icon: const Icon(Icons.perm_media),
              label: const Text('Ver evidencia'),
            ),
          ],
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onGoToDashboard,
          icon: const Icon(Icons.home_outlined),
          label: Text(isWorker ? 'Volver al panel' : 'Volver al inicio'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
