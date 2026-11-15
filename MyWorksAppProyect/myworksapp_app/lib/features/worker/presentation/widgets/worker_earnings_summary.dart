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
        return WorkerEarningsCard(data: data, onViewDetails: onViewDetails);
      },
    );
  }
}

/// Contenido de la tarjeta. Se adapta al ancho: si no cabe el botón al lado
/// del texto (pantallas angostas o fuente grande), el botón baja a su propia
/// fila. Así el texto nunca queda en una columna de una letra.
class WorkerEarningsCard extends StatelessWidget {
  final WorkerEarningsSnapshot data;
  final VoidCallback? onViewDetails;

  const WorkerEarningsCard({
    super.key,
    required this.data,
    this.onViewDetails,
  });

  /// Ancho mínimo (en px lógicos, ya escalado por la fuente) que necesita el
  /// bloque de texto para quedar en línea con el botón.
  static const double _minTextWidth = 170;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_CL',
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = AppColors.onCanvas(brightness);
    final muted = AppColors.onCanvasMuted(brightness);
    final total = data.releasedClp + data.escrowClp;
    final growthPercent = data.paymentCount > 0 ? 12 : 0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    final icon = Container(
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
    );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ganancias totales',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            _currency.format(total),
            maxLines: 1,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: titleColor,
            ),
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
              Flexible(
                child: Text(
                  '$growthPercent% vs. mes anterior',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
        ] else if (data.paymentCount == 0) ...[
          const SizedBox(height: 4),
          Text(
            'Se mostrarán al confirmar pagos',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
        ],
      ],
    );

    final button = OutlinedButton(
      onPressed: onViewDetails,
      style: OutlinedButton.styleFrom(
        // El tema global usa minimumSize de ancho infinito (botones de
        // formulario a todo el ancho). Dentro de un Row eso deja el texto
        // sin espacio y lo parte letra por letra.
        minimumSize: const Size(0, 40),
        foregroundColor: AppColors.brandOrange,
        side: BorderSide(
          color: AppColors.brandOrange.withValues(alpha: 0.65),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Ver detalles',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.surfaceCardOf(
          context,
          accent: AppColors.brandOrange,
          radius: 16,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Ícono (44) + separación (12) + botón (~130 escalado) + 8.
            final buttonWidth = 130 * textScale;
            final textWidth = constraints.maxWidth - 44 - 12 - 8 - buttonWidth;
            final inline = textWidth >= _minTextWidth * textScale.clamp(1, 2);

            if (inline) {
              return Row(
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(child: texts),
                  const SizedBox(width: 8),
                  button,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: texts),
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: button),
              ],
            );
          },
        ),
      ),
    );
  }
}
