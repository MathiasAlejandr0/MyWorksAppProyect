import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// PIN que el cliente le dicta al profesional para iniciar el trabajo.
class ClientStartPinCard extends StatelessWidget {
  const ClientStartPinCard({super.key, required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandOrange.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PIN para iniciar',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandNavy,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Díselo al profesional cuando llegue. Sin este PIN no puede dejar el trabajo en curso.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grayMedium,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                pin,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: AppColors.brandNavy,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copiar PIN',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pin));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN copiado')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, color: AppColors.brandOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
