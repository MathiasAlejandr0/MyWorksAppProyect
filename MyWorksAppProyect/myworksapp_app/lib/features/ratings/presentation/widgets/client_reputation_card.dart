import 'package:flutter/material.dart';

import '../../../../core/database/repositories/client_rating_repository.dart';
import '../../../../core/theme/app_colors.dart';

/// Nota que los especialistas dejan al cliente, más las disputas que abrió.
class ClientReputationCard extends StatelessWidget {
  const ClientReputationCard({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClientReputation?>(
      future: ClientRatingRepository().fetchReputation(clientId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final score = data?.score;
        final scoreLabel = score == null ? 'Sin notas aún' : score.toStringAsFixed(1);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reputación como cliente',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else if (snapshot.hasError)
                  const Text('La reputación no está disponible en este momento.')
                else ...[
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        scoreLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text('${data?.ratings ?? 0} notas de especialistas'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data?.disputes ?? 0} disputas abiertas por esta cuenta. '
                    'Sirve para ver si se rechaza la conformidad sin fundamento.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
