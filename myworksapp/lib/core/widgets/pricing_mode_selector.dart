import 'package:flutter/material.dart';

import '../domain/pricing_constants.dart';
import '../theme/app_colors.dart';

/// Selector de modalidad de cobro en solicitud de servicio.
class PricingModeSelector extends StatelessWidget {
  const PricingModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.workerPreselected = false,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final bool workerPreselected;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Forma de cobro', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _tile(
          context,
          mode: PricingConstants.modeOpenQuote,
          title: 'Cotización abierta',
          subtitle: 'Varios trabajadores envían su precio. Tú eliges y pagas en garantía.',
          icon: Icons.request_quote_outlined,
        ),
        if (workerPreselected) ...[
          _tile(
            context,
            mode: PricingConstants.modeFixedPrice,
            title: 'Precio fijo',
            subtitle: 'Ítem catalogado con precio estimado + pago en garantía.',
            icon: Icons.price_check_outlined,
          ),
          _tile(
            context,
            mode: PricingConstants.modeHourlyBlock,
            title: 'Por bloque de horas',
            subtitle: 'Pagas 2, 4 u 8 horas por adelantado. Horas extra se cotizan aparte.',
            icon: Icons.schedule_outlined,
          ),
        ],
        _tile(
          context,
          mode: PricingConstants.modeLegacy,
          title: 'Solicitud clásica',
          subtitle: 'Sin pago adelantado en la app (flujo demo anterior).',
          icon: Icons.history,
        ),
          if (!workerPreselected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Precio fijo y bloque de horas requieren elegir un trabajador antes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grayMedium,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selected == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppColors.brandOrangeSoft
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(mode),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? AppColors.brandOrange : AppColors.grayMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Radio<String>(
                  value: mode,
                  activeColor: AppColors.brandOrange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
