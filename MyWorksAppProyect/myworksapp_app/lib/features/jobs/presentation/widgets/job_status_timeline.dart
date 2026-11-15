import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../utils/job_detail_helpers.dart';

const jobTimelineSteps = <String>[
  AppConstants.jobStatusPending,
  AppConstants.jobStatusAccepted,
  AppConstants.jobStatusEnRoute,
  AppConstants.jobStatusInProgress,
  PricingConstants.jobAwaitingClientApproval,
  AppConstants.jobStatusCompleted,
];

int jobTimelineIndex(String status) => jobTimelineSteps.indexOf(status);

class JobStatusTimeline extends StatelessWidget {
  const JobStatusTimeline({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final current = jobTimelineIndex(status);
    final terminal = status == AppConstants.jobStatusCancelled ||
        status == AppConstants.jobStatusExpired ||
        status == AppConstants.jobStatusNoShow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Línea de tiempo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (terminal)
          Text(
            JobDetailHelpers.statusText(status),
            style: TextStyle(color: JobDetailHelpers.statusColor(status), fontWeight: FontWeight.w700),
          )
        else
          for (var i = 0; i < jobTimelineSteps.length; i++)
            _Step(
              label: JobDetailHelpers.statusText(jobTimelineSteps[i]),
              done: current >= 0 && i < current,
              current: i == current,
            ),
        if (current < 0 && !terminal)
          Text(JobDetailHelpers.statusText(status)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done, required this.current});

  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color = current
        ? AppColors.brandOrange
        : done
            ? AppColors.success
            : AppColors.grayMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            current ? Icons.radio_button_checked : done ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: current ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
