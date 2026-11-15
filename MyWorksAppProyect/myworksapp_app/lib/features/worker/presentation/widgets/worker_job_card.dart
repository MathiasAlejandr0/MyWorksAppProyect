import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/job_display_utils.dart';
import '../../../../core/utils/job_status_copy.dart';
import '../../../../core/utils/santiago_time.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../ratings/presentation/widgets/client_rating_badge.dart';

/// Tarjeta de trabajo en las pestañas del panel del trabajador (mockup worker-home).
class WorkerJobCard extends StatefulWidget {
  const WorkerJobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.clientRatingLabel,
    this.clientName,
    this.priceLabel,
  });

  final JobModel job;
  final VoidCallback onTap;
  final String? clientRatingLabel;
  final String? clientName;
  final String? priceLabel;

  @override
  State<WorkerJobCard> createState() => _WorkerJobCardState();
}

class _WorkerJobCardState extends State<WorkerJobCard> {
  String _displayAddress = '';
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final address = await LocationUtils.getLocationTextForJob(
        address: widget.job.address,
        status: widget.job.status,
        latitude: widget.job.latitude,
        longitude: widget.job.longitude,
      );
      if (mounted) {
        setState(() {
          _displayAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _displayAddress = widget.job.address;
          _isLoadingAddress = false;
        });
      }
    }
  }

  String _statusLabel(String status) => JobStatusCopy.chipLabel(status);

  Color _statusColor(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
        return AppColors.brandOrange;
      case AppConstants.jobStatusInProgress:
        return AppColors.info;
      case AppConstants.jobStatusCompleted:
        return AppColors.emerald;
      default:
        return JobStatusCopy.color(status);
    }
  }

  String _clientLine() {
    final name = widget.clientName?.trim();
    if (name == null || name.isEmpty) return 'Cliente';
    return name;
  }

  (String date, String? time) _scheduleParts() {
    final rawScheduled = widget.job.scheduledDate;
    if (rawScheduled != null) {
      final scheduled = SantiagoTime.wall(rawScheduled);
      return (
        DateFormat('d MMM y', 'es_CL').format(scheduled),
        DateFormat('HH:mm', 'es_CL').format(scheduled),
      );
    }
    return (
      DateFormat('d MMM y', 'es_CL').format(SantiagoTime.wall(widget.job.createdAt)),
      null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final statusColor = _statusColor(widget.job.status);
    final schedule = _scheduleParts();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.surfaceCardOf(
        context,
        accent: AppColors.brandOrange,
        radius: 16,
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: AppColors.brandOrange.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.brandOrange.withValues(alpha: 0.7),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        _statusLabel(widget.job.status),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.job.status ==
                            AppConstants.jobStatusPending) ...[
                          Text(
                            _clientLine(),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.priceLabel ??
                                JobDisplayUtils.offeredAmountLabel(widget.job),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.brandOrange,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          JobDisplayUtils.title(widget.job),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            letterSpacing: -0.2,
                            height: 1.25,
                            color: titleColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLoadingAddress
                              ? 'Cargando ubicación...'
                              : _displayAddress,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: muted,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    schedule.$1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (schedule.$2 != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      schedule.$2!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.job.status == AppConstants.jobStatusPending &&
                  widget.clientRatingLabel != null) ...[
                const SizedBox(height: 8),
                ClientRatingBadge(label: widget.clientRatingLabel!),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: widget.onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandOrange,
                  side: BorderSide(
                    color: AppColors.brandOrange.withValues(alpha: 0.65),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Ver detalles del trabajo',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
