import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/models/worker_review_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';

/// Opiniones y calificaciones de clientes anteriores en el perfil del trabajador.
class WorkerReviewsSection extends StatelessWidget {
  const WorkerReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
  });

  final List<WorkerReviewModel> reviews;
  final double averageRating;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.rate_review_outlined,
                color: AppColors.brandOrange, size: 22),
            const SizedBox(width: 8),
            Text(
              'Opiniones de clientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          const EmptyStateWidget(
            icon: Icons.chat_bubble_outline,
            title: 'Sin opiniones aún',
            message:
                'Cuando clientes califiquen a este profesional, sus comentarios aparecerán aquí.',
          )
        else ...[
          _SummaryCard(
            averageRating: _resolvedAverage(averageRating, reviews),
            totalReviews: reviews.length,
          ),
          const SizedBox(height: 12),
          ...reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReviewCard(review: review),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.averageRating,
    required this.totalReviews,
  });

  final double averageRating;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCard(accent: AppColors.brandOrange),
      child: Row(
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandOrange,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StarRow(score: averageRating.floor().clamp(0, 5), size: 18),
                const SizedBox(height: 4),
                Text(
                  '$totalReviews ${totalReviews == 1 ? 'opinión' : 'opiniones'} de clientes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grayMedium,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCard(accent: AppColors.brandOrange),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandOrangeSoft,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.brandOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.displayReviewerName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grayMedium,
                          ),
                    ),
                  ],
                ),
              ),
              _StarRow(score: review.score, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          if (review.hasComment)
            Text(
              review.comment!.trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: AppColors.grayDark,
                  ),
            )
          else
            Text(
              'Calificó con ${review.score} ${review.score == 1 ? 'estrella' : 'estrellas'} sin dejar comentario.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayMedium,
                    fontStyle: FontStyle.italic,
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
          color: filled ? AppColors.warning : AppColors.grayMedium.withValues(alpha: 0.35),
        );
      }),
    );
  }
}
