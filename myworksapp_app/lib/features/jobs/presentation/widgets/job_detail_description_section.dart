import 'package:flutter/material.dart';

import '../../../../core/database/models/job_model.dart';

class JobDetailDescriptionSection extends StatelessWidget {
  final JobModel job;

  const JobDetailDescriptionSection({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          job.description ?? 'Sin descripción',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
