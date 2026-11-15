import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class JobDetailScheduledDateRow extends StatelessWidget {
  final DateTime scheduledDate;

  const JobDetailScheduledDateRow({
    super.key,
    required this.scheduledDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.event, color: AppColors.brandOrange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Solicitado: ${DateFormat('EEE d MMM · HH:mm', 'es_CL').format(scheduledDate)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
