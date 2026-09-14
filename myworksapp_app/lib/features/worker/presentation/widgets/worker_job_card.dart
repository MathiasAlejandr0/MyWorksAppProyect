import 'package:flutter/material.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/job_display_utils.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/widgets/design_system/status_badge.dart';

/// Tarjeta de trabajo en las pestañas del panel del trabajador.
class WorkerJobCard extends StatefulWidget {
  const WorkerJobCard({super.key, required this.job, required this.onTap});

  final JobModel job;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.grayMedium.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      JobDisplayUtils.title(widget.job),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.grayDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: widget.job.status, compact: true),
                ],
              ),
              if (JobDisplayUtils.priceLine(widget.job) != null) ...[
                const SizedBox(height: 4),
                Text(
                  JobDisplayUtils.priceLine(widget.job)!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandOrange,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    widget.job.status == AppConstants.jobStatusPending
                        ? Icons.location_searching
                        : Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isLoadingAddress ? 'Cargando ubicación...' : _displayAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grayMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.grayMedium.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(
                    JobDisplayUtils.dateLine(widget.job),
                    style: const TextStyle(
                      color: AppColors.grayMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
