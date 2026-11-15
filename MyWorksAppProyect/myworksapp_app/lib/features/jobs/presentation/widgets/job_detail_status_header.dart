import 'package:flutter/material.dart';
import '../../../../core/database/models/job_model.dart';
import '../utils/job_detail_helpers.dart';

class JobDetailStatusHeader extends StatelessWidget {
  final JobModel job;

  const JobDetailStatusHeader({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final color = JobDetailHelpers.statusColor(job.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(JobDetailHelpers.statusIcon(job.status), color: color),
          const SizedBox(width: 12),
          Text(
            JobDetailHelpers.statusText(job.status),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
