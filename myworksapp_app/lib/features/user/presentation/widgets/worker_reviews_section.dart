import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/models/worker_review_model.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';

/// Opiniones compactas en el perfil del trabajador (alineadas al portafolio).
class WorkerReviewsSection extends StatelessWidget {
  const WorkerReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    this.maxVisible,
  });

  final List<WorkerReviewModel> reviews;
  final double averageRating;
  final int? maxVisible;

  static const double _reviewCardWidth = 260;
  static const double _reviewStripHeight = 132;

  static double _resolvedAverage(
    double workerAverage,
    List<WorkerReviewModel> reviews,
  ) {
    if (reviews.isEmpty) return workerAverage;
    if (workerAverage > 0) return workerAverage;
    final total = reviews.fold<int>(0, (sum, r) => sum + r.score);
    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final visibleReviews = maxVisible == null
        ? reviews
        : reviews.take(maxVisible!).toList();
    final hiddenCount =
        maxVisible == null ? 0 : reviews.length - visibleReviews.length;
    final avg = _resolvedAverage(averageRating, reviews);

    final stripItemCount =
        visibleReviews.length + (hiddenCount > 0 ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              color: AppColors.brandOrange,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Opiniones de clientes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (reviews.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${reviews.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.grayMedium,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (reviews.isEmpty)
          const EmptyStateWidget(
            icon: Icons.chat_bubble_outline,
            title: 'Sin opiniones aún',
            message:
                'Cuando clientes califiquen a este profesional, sus comentarios aparecerán aquí.',
          )
        else ...[
          _SummaryStrip(
            averageRating: avg,
            totalReviews: reviews.length,
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = AppSpacing.sm;
              final moreWidth = hiddenCount > 0 ? 88.0 : 0.0;
              final reviewsWidth = visibleReviews.length * _reviewCardWidth +
                  (visibleReviews.isNotEmpty ? (visibleReviews.length - 1) * spacing : 0);
              final totalWidth = reviewsWidth +
                  (hiddenCount > 0 ? spacing + moreWidth : 0);
              final fits = totalWidth <= constraints.maxWidth;

              if (fits) {
                return SizedBox(
                  height: _reviewStripHeight,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < visibleReviews.length; i++) ...[
                          if (i > 0) const SizedBox(width: spacing),
                          SizedBox(
                            width: _reviewCardWidth,
                            height: _reviewStripHeight,
                            child: _ReviewCard(review: visibleReviews[i]),
                          ),
                        ],
                        if (hiddenCount > 0) ...[
                          const SizedBox(width: spacing),
                          SizedBox(
                            width: moreWidth,
                            height: _reviewStripHeight,
                            child: _MoreReviewsChip(hiddenCount: hiddenCount),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: _reviewStripHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stripItemCount,
                  separatorBuilder: (_, __) => const SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    if (hiddenCount > 0 && index == visibleReviews.length) {
                      return SizedBox(
                        width: moreWidth,
                        height: _reviewStripHeight,
                        child: _MoreReviewsChip(hiddenCount: hiddenCount),
                      );
                    }
                    return SizedBox(
                      width: _reviewCardWidth,
                      height: _reviewStripHeight,
                      child: _ReviewCard(review: visibleReviews[index]),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.averageRating,
    required this.totalReviews,
  });

  final double averageRating;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brandOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandOrange,
                ),
          ),
          const SizedBox(width: 8),
          _StarRow(score: averageRating.round().clamp(0, 5), size: 14),
          const SizedBox(width: 10),
          Text(
            '· $totalReviews ${totalReviews == 1 ? 'opinión' : 'opiniones'}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.grayMedium,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoreReviewsChip extends StatelessWidget {
  const _MoreReviewsChip({required this.hiddenCount});

  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: AppDecorations.surfaceCard(accent: AppColors.grayMedium),
      child: Text(
        '+$hiddenCount\n${hiddenCount == 1 ? 'más' : 'más'}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.grayMedium,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final WorkerReviewModel review;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy', 'es_CL').format(review.createdAt);
    final initial = review.displayReviewerName.isNotEmpty
        ? review.displayReviewerName[0].toUpperCase()
        : 'C';

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: AppDecorations.surfaceCard(accent: AppColors.brandOrange),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.brandOrangeSoft,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.brandOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.displayReviewerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.grayMedium,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _StarRow(score: review.score, size: 12),
          const SizedBox(height: 6),
          Expanded(
            child: review.hasComment
                ? Text(
                    review.comment!.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: AppColors.grayDark,
                        ),
                  )
                : Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Sin comentario escrito.',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grayMedium,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.score, this.size = 16});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < score;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled
              ? AppColors.warning
              : AppColors.grayMedium.withValues(alpha: 0.35),
        );
      }),
    );
  }
}
