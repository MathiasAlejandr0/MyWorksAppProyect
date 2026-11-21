import 'package:flutter/material.dart';

import '../../../../core/domain/escrow_confirmation.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/job_status_copy.dart';
import 'job_status_timeline.dart';

/// Etiquetas cortas, en el mismo orden que [jobTimelineSteps].
const jobHistoryPhaseLabels = <String>[
  'Espera',
  'Acepta',
  'Camino',
  'Curso',
  'Conforme',
  'Listo',
];

/// Trabajo con el pago ya retenido y todavía abierto.
///
/// `esperando_pago` no entra: el cobro aún no quedó en garantía.
/// `pausado_orden_cambio` sí: el trabajo sigue abierto y el pago retenido.
bool jobHistoryIsLive(String status) {
  if (status == PricingConstants.jobPausedChangeOrder) return true;
  if (status == AppConstants.jobStatusCompleted) return false;
  return escrowHoldAlreadyConfirmed(status);
}

/// Índice de la fase visible. El cobro extra deja el trabajo en «en curso».
int jobHistoryPhaseIndex(String status) {
  if (status == PricingConstants.jobPausedChangeOrder) {
    return jobTimelineIndex(AppConstants.jobStatusInProgress);
  }
  return jobTimelineIndex(status);
}

/// Carta del historial mientras el pago sigue retenido.
class JobHistoryLiveCard extends StatelessWidget {
  const JobHistoryLiveCard({
    super.key,
    required this.title,
    required this.address,
    required this.dateLabel,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String address;
  final String dateLabel;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final phase = jobHistoryPhaseIndex(status);
    final step = phase < 0 ? 0 : phase + 1;
    final total = jobTimelineSteps.length;
    final statusLabel = JobStatusCopy.label(status);
    final paused = status == PricingConstants.jobPausedChangeOrder;
    final next = paused ? null : jobProgressNextStatus(status);

    return Semantics(
      button: true,
      label: 'Trabajo con pago retenido, $title, $statusLabel',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: AppDecorations.surfaceCardOf(
          context,
          accent: AppColors.brandOrange,
          radius: 20,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.brandOrange.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.brandOrange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Pago retenido',
                          style: TextStyle(
                            color: AppColors.brandOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Text(
                        step == 0 ? '' : '$step/$total',
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _HorizontalPhaseTrack(currentIndex: phase),
                  const SizedBox(height: 12),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Siguiente: ${JobStatusCopy.label(next)}',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carta de un trabajo ya cerrado con conformidad. Distinta al recorrido activo.
class JobHistoryCompletedCard extends StatelessWidget {
  const JobHistoryCompletedCard({
    super.key,
    required this.title,
    required this.address,
    required this.dateLabel,
    required this.paymentStatus,
    required this.onTap,
  });

  final String title;
  final String address;
  final String dateLabel;
  final String paymentStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final released = paymentStatus == PricingConstants.paymentReleased;

    return Semantics(
      button: true,
      label: 'Trabajo completado, $title',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.emerald.withValues(alpha: isDark ? 0.22 : 0.14),
              surface,
              surface,
            ],
            stops: const [0, 0.42, 1],
          ),
          border: Border.all(
            color: AppColors.emerald.withValues(alpha: isDark ? 0.55 : 0.38),
          ),
          boxShadow: AppDecorations.appleCardShadow(
            accent: AppColors.emerald,
            isDark: isDark,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _CompletedSeal(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'COMPLETADO',
                              style: TextStyle(
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateLabel,
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: muted),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.3),
                  ),
                  if (released) ...[
                    const SizedBox(height: 12),
                    const _ReleasedPill(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cancelados, expirados y pedidos que todavía no tienen el pago retenido.
class JobHistoryClosedCard extends StatelessWidget {
  const JobHistoryClosedCard({
    super.key,
    required this.title,
    required this.address,
    required this.dateLabel,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String address;
  final String dateLabel;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final statusColor = JobStatusCopy.color(status);

    return Semantics(
      button: true,
      label: '${JobStatusCopy.label(status)}, $title',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: AppDecorations.surfaceCardOf(
          context,
          accent: statusColor,
          radius: 18,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$dateLabel · ${JobStatusCopy.label(status)}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(JobStatusCopy.icon(status), color: statusColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalPhaseTrack extends StatelessWidget {
  const _HorizontalPhaseTrack({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);
    assert(jobHistoryPhaseLabels.length == jobTimelineSteps.length);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < jobHistoryPhaseLabels.length; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 26,
                  child: Row(
                    children: [
                      Expanded(
                        child: _connector(
                          visible: i > 0,
                          filled: i > 0 && i <= currentIndex,
                        ),
                      ),
                      _PhaseNode(
                        done: currentIndex >= 0 && i < currentIndex,
                        current: i == currentIndex,
                      ),
                      Expanded(
                        child: _connector(
                          visible: i < jobHistoryPhaseLabels.length - 1,
                          filled: i < currentIndex,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  jobHistoryPhaseLabels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: i == currentIndex
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: i == currentIndex
                        ? AppColors.brandOrange
                        : currentIndex >= 0 && i < currentIndex
                            ? AppColors.emerald
                            : muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _connector({required bool visible, required bool filled}) {
    return Container(
      height: 2,
      color: visible
          ? (filled
              ? AppColors.emerald.withValues(alpha: 0.9)
              : AppColors.grayMedium.withValues(alpha: 0.35))
          : Colors.transparent,
    );
  }
}

class _PhaseNode extends StatelessWidget {
  const _PhaseNode({required this.done, required this.current});

  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final size = current ? 22.0 : 16.0;
    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: current
          ? AppColors.brandOrange
          : done
              ? AppColors.emerald
              : Colors.transparent,
      border: current || done
          ? Border.all(color: Colors.white.withValues(alpha: 0.45))
          : Border.all(
              color: AppColors.grayMedium.withValues(alpha: 0.7),
              width: 1.4,
            ),
      boxShadow: current || done
          ? [
              BoxShadow(
                color: (current ? AppColors.brandOrange : AppColors.emerald)
                    .withValues(alpha: current ? 0.45 : 0.35),
                blurRadius: current ? 8 : 6,
              ),
            ]
          : null,
    );

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
          : current
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
    );
  }
}

class _CompletedSeal extends StatelessWidget {
  const _CompletedSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF49C484), AppColors.emerald],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
    );
  }
}

class _ReleasedPill extends StatelessWidget {
  const _ReleasedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: AppColors.emerald),
          SizedBox(width: 6),
          Text(
            'Pago liberado',
            style: TextStyle(
              color: AppColors.emerald,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
