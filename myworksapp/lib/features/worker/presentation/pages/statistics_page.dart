import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/repositories/job_repository.dart';
import '../../../../core/database/repositories/rating_repository.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  final JobRepository _jobRepository = JobRepository();
  final RatingRepository _ratingRepository = RatingRepository();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Estadísticas'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          _jobRepository.getJobsByWorkerId(user.id),
          _ratingRepository.getAverageRatingByWorkerId(user.id),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final results = snapshot.data as List;
          final jobs = results[0] as List;
          final avgRating = results[1] as double;

          final completed = jobs.where((j) => j.status == AppConstants.jobStatusCompleted).length;
          final inProgress = jobs.where((j) => j.status == AppConstants.jobStatusInProgress).length;
          final pending = jobs.where((j) => j.status == AppConstants.jobStatusPending).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Resumen general
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Resumen General',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatCard(
                              icon: Icons.work,
                              label: 'Total',
                              value: jobs.length.toString(),
                              color: Colors.blue,
                            ),
                            _StatCard(
                              icon: Icons.check_circle,
                              label: 'Completados',
                              value: completed.toString(),
                              color: Colors.green,
                            ),
                            _StatCard(
                              icon: Icons.star,
                              label: 'Calificación',
                              value: avgRating.toStringAsFixed(1),
                              color: Colors.amber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Estados de trabajos
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de Trabajos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _StatusItem(
                          label: 'Completados',
                          count: completed,
                          total: jobs.length,
                          color: Colors.green,
                        ),
                        _StatusItem(
                          label: 'En Progreso',
                          count: inProgress,
                          total: jobs.length,
                          color: Colors.purple,
                        ),
                        _StatusItem(
                          label: 'Pendientes',
                          count: pending,
                          total: jobs.length,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$count de $total'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}

