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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.white : AppColors.brandNavy;
    final muted = isDark
        ? AppColors.white.withValues(alpha: 0.65)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDarkElevated : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.brandOrange.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandOrange.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandOrange.withValues(alpha: 0.28),
                        AppColors.brandOrange.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    color: AppColors.brandOrange,
                  ),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        JobDisplayUtils.title(job),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: titleColor,
                        ),
                      ),
                      if (JobDisplayUtils.priceLine(job) != null)
                        Text(
                          JobDisplayUtils.priceLine(job)!,
                          style: const TextStyle(
                            color: AppColors.brandOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      Text(
                        JobDisplayUtils.dateLine(job),
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onChat,
                  icon: Icon(
                    Icons.chat_bubble_rounded,
                    color: isDark ? AppColors.white : AppColors.brandOrange,
                  ),
                  tooltip: 'Chat',
                ),
                Icon(Icons.chevron_right, color: muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
