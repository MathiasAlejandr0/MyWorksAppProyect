import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/worker_earnings_snapshot.dart';
import '../../../../core/services/worker_earnings_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Tarjeta compacta con cobros en garantía y liberados (demo).
class WorkerEarningsSummary extends StatelessWidget {
  final String workerId;

  const WorkerEarningsSummary({super.key, required this.workerId});

  static final NumberFormat _clp = NumberFormat.currency(
    locale: 'es_CL',
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkerEarningsSnapshot>(
      future: WorkerEarningsService.instance.getSnapshot(workerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: SizedBox(
              height: 56,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? WorkerEarningsSnapshot.zero;
        if (data.paymentCount == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.grayMedium.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.grayMedium.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aún no hay cobros registrados. Se mostrarán al confirmar pagos en garantía.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grayMedium,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.brandTeal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mis cobros (demo)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.grayDark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _EarningsMetric(
                        label: 'En garantía',
                        value: _clp.format(data.escrowClp),
                        color: AppColors.brandOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _EarningsMetric(
                        label: 'Liberados',
                        value: _clp.format(data.releasedClp),
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                if (data.pendingClp > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Pendientes: ${_clp.format(data.pendingClp)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
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

class _EarningsMetric extends StatelessWidget {
  const _EarningsMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.grayDark,
            ),
          ),
        ],
      ),
    );
  }
}
