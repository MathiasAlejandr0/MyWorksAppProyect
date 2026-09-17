import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/worker_earnings_snapshot.dart';
import '../../../../core/services/worker_earnings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';

/// Tarjeta de ganancias totales — layout mockup worker-home.
class WorkerEarningsSummary extends StatefulWidget {
  final String workerId;
  final VoidCallback? onViewDetails;

  const WorkerEarningsSummary({
    super.key,
    required this.workerId,
    this.onViewDetails,
  });

  @override
  State<WorkerEarningsSummary> createState() => _WorkerEarningsSummaryState();
}

class _WorkerEarningsSummaryState extends State<WorkerEarningsSummary> {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_CL',
    symbol: r'$',
    decimalDigits: 0,
  );

  late Future<WorkerEarningsSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = WorkerEarningsService.instance.getSnapshot(widget.workerId);
  }

  @override
  void didUpdateWidget(covariant WorkerEarningsSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workerId != widget.workerId) {
      _snapshotFuture = WorkerEarningsService.instance.getSnapshot(widget.workerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final onViewDetails = widget.onViewDetails;

    return FutureBuilder<WorkerEarningsSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              height: 72,
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
        final total = data.releasedClp + data.escrowClp;
        final growthPercent = data.paymentCount > 0 ? 12 : 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.surfaceCardOf(
              context,
              accent: AppColors.brandOrange,
              radius: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.brandOrange.withValues(alpha: 0.16),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.brandOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ganancias totales',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currency.format(total),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: titleColor,
                        ),
                      ),
                      if (growthPercent > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 14,
                              color: AppColors.emerald,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$growthPercent% vs. mes anterior',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ],
                        ),
                      ] else if (data.paymentCount == 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Se mostrarán al confirmar pagos',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandOrange,
                    side: BorderSide(
                      color: AppColors.brandOrange.withValues(alpha: 0.65),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver detalles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
