import 'package:flutter/material.dart';

import '../../../../core/database/models/change_order_model.dart';
import '../../../../core/theme/app_colors.dart';

class ChangeOrdersSection extends StatelessWidget {
  const ChangeOrdersSection({
    super.key,
    required this.orders,
    required this.isWorker,
    this.onReview,
    this.onRequest,
    this.canRequest = false,
  });

  final List<ChangeOrderModel> orders;
  final bool isWorker;
  final bool canRequest;
  final void Function(ChangeOrderModel order)? onReview;
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty && !canRequest) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cobros adicionales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (canRequest && isWorker && onRequest != null)
              TextButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Solicitar'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          Text(
            'Sin cobros adicionales por ahora.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grayMedium,
                ),
          )
        else
          ...orders.map((o) => _ChangeOrderTile(
                order: o,
                isWorker: isWorker,
                onReview: onReview,
              )),
      ],
    );
  }
}

class _ChangeOrderTile extends StatelessWidget {
  const _ChangeOrderTile({
    required this.order,
    required this.isWorker,
    this.onReview,
  });

  final ChangeOrderModel order;
  final bool isWorker;
  final void Function(ChangeOrderModel order)? onReview;

  String _statusLabel(String estado) {
    switch (estado) {
      case 'pending_client':
        return 'Pendiente de tu aprobación';
      case 'paid':
        return 'Pagado';
      case 'rejected':
        return 'Rechazado';
      default:
        return estado;
    }
  }

  Color _statusColor(String estado) {
    switch (estado) {
      case 'pending_client':
        return AppColors.brandOrange;
      case 'paid':
        return AppColors.success;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.grayMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canReview = !isWorker && order.isPendingClient && onReview != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.titulo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.estado).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(order.estado),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _statusColor(order.estado),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(order.descripcion),
            const SizedBox(height: 8),
            Text(
              '\$${order.montoClp}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.brandOrange,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (canReview) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => onReview!(order),
                  child: const Text('Revisar y decidir'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
