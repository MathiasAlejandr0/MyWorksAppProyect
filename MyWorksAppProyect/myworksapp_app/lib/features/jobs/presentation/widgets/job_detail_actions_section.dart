import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/repositories/rating_repository.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../ratings/presentation/widgets/client_reputation_card.dart';
import '../../../ratings/presentation/widgets/rate_client_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../ratings/domain/client_rating_label.dart';
import '../../../ratings/presentation/widgets/client_rating_badge.dart';
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
  final VoidCallback onMarkEnRoute;
  final VoidCallback onStartJob;
  final VoidCallback onRequestOvertimeHours;
  final VoidCallback onCompleteJob;

  /// La página ya cargó la disputa; no se vuelve a pedir en cada build.
  final bool ratingBlockedByDispute;

  /// Ya hay una calificación de quien mira esta pantalla (puesta aquí o en la web).
  final bool alreadyRated;

  /// Se llama cuando la persona volvió de calificar, para releer el estado.
  final VoidCallback? onRatingChanged;

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
    required this.onMarkEnRoute,
    required this.onStartJob,
    required this.onRequestOvertimeHours,
    required this.onCompleteJob,
    this.ratingBlockedByDispute = false,
    this.alreadyRated = false,
    this.onRatingChanged,
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
            FutureBuilder<Map<String, ClientRatingSummary>>(
              future: RatingRepository().clientSummaries([job.userId]),
              builder: (context, snapshot) {
                final ready = snapshot.connectionState == ConnectionState.done;
                if (!ready) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }
                final summary = snapshot.data?[job.userId];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClientRatingBadge(
                    label: clientRatingLabel(
                      average: summary?.average,
                      count: summary?.count ?? 0,
                      known: !snapshot.hasError,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton(
              onPressed: onAcceptJob,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Aceptar Trabajo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRejectJob,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Rechazar'),
            ),
          ],
          if (JobDetailHelpers.canOpenChat(job.status)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                context.push('${AppConstants.routeChat}/$jobId');
              },
              icon: const Icon(Icons.chat),
              label: const Text('Abrir Chat'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          if (isWorker && job.status == AppConstants.jobStatusAccepted) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onMarkEnRoute,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Voy en camino'),
            ),
          ],
          if (isWorker && job.status == AppConstants.jobStatusEnRoute) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onStartJob,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Iniciar trabajo'),
            ),
          ],
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
          if (isWorker) ...[
            ClientReputationCard(clientId: job.userId),
            if (job.status == AppConstants.jobStatusCompleted) ...[
              const SizedBox(height: 8),
              if (alreadyRated)
                const _RatedNotice(text: 'Ya calificaste al cliente.')
              else
                RateClientButton(jobId: jobId, onSaved: onRatingChanged),
            ],
            const SizedBox(height: 8),
          ],
          if (!isWorker && job.status == AppConstants.jobStatusCompleted)
            if (ratingBlockedByDispute)
              const Text(
                'Calificación bloqueada por disputa abierta.',
                style: TextStyle(color: AppColors.warning),
              )
            else if (alreadyRated)
              const _RatedNotice(text: 'Ya calificaste este trabajo.')
            else
              ElevatedButton(
                onPressed: () async {
                  await context.push('${AppConstants.routeRating}/$jobId');
                  onRatingChanged?.call();
                },
                child: const Text('Calificar Trabajo'),
              ),
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

class _RatedNotice extends StatelessWidget {
  const _RatedNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
