import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ClientRatingBadge extends StatelessWidget {
  const ClientRatingBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isNew = label == 'Cliente nuevo';
    return Row(
      children: [
        Icon(
          isNew ? Icons.person_outline : Icons.star_rounded,
          size: 16,
          color: isNew ? AppColors.grayDark : AppColors.brandOrange,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isNew ? AppColors.grayDark : AppColors.brandNavy,
            ),
          ),
        ),
      ],
    );
  }
}
