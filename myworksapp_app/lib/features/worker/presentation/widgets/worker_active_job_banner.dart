import 'package:flutter/material.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/job_display_utils.dart';
import '../../../../core/utils/worker_job_status.dart';

class WorkerActiveJobBanner extends StatelessWidget {
  const WorkerActiveJobBanner({
    super.key,
    required this.job,
    required this.onTap,
    required this.onChat,
  });

  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.brandOrange.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work_outline,
                      color: AppColors.brandOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        WorkerJobStatus.activeBannerTitle(job.status),
                        style: const TextStyle(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        JobDisplayUtils.title(job),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.grayDark,
                        ),
                      ),
                      if (JobDisplayUtils.priceLine(job) != null)
                        Text(
                          JobDisplayUtils.priceLine(job)!,
                          style: const TextStyle(
                            color: AppColors.brandOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        JobDisplayUtils.dateLine(job),
                        style: const TextStyle(
                          color: AppColors.grayMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.brandTeal),
                  tooltip: 'Chat',
                ),
                Icon(Icons.chevron_right,
                    color: AppColors.grayMedium.withValues(alpha: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
