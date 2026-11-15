import 'package:flutter/material.dart';

import '../domain/pricing_constants.dart';
import '../theme/app_colors.dart';
import 'constants.dart';

/// Texto, ícono y color de cada estado de trabajo.
///
/// Fuente única para tarjetas, historial, badges y detalle. Un estado nuevo
/// que llegue desde la base sin traducción muestra «Estado desconocido» en
/// vez del valor crudo (`esperando_pago`, `en_camino`, …).
class JobStatusCopy {
  JobStatusCopy._();

  static const String unknownLabel = 'Estado desconocido';

  static const Map<String, String> _labels = {
    AppConstants.jobStatusPending: 'Pendiente',
    AppConstants.jobStatusAccepted: 'Aceptado',
    AppConstants.jobStatusEnRoute: 'En camino',
    AppConstants.jobStatusInProgress: 'En curso',
    AppConstants.jobStatusCompleted: 'Completado',
    AppConstants.jobStatusCancelled: 'Cancelado',
    AppConstants.jobStatusExpired: 'Expirado',
    AppConstants.jobStatusNoShow: 'No asistió',
    PricingConstants.jobAwaitingPayment: 'Esperando pago',
    PricingConstants.jobAwaitingQuotes: 'Esperando cotizaciones',
    PricingConstants.jobQuoteSelected: 'Cotización elegida',
    PricingConstants.jobPausedChangeOrder: 'Cobro extra pendiente',
    PricingConstants.jobAwaitingClientApproval: 'Esperando conformidad',
  };

  static const Map<String, IconData> _icons = {
    AppConstants.jobStatusPending: Icons.pending_outlined,
    AppConstants.jobStatusAccepted: Icons.check_circle_outline,
    AppConstants.jobStatusEnRoute: Icons.directions_car_outlined,
    AppConstants.jobStatusInProgress: Icons.handyman_outlined,
    AppConstants.jobStatusCompleted: Icons.task_alt,
    AppConstants.jobStatusCancelled: Icons.cancel_outlined,
    AppConstants.jobStatusExpired: Icons.timer_off_outlined,
    AppConstants.jobStatusNoShow: Icons.person_off_outlined,
    PricingConstants.jobAwaitingPayment: Icons.payment_outlined,
    PricingConstants.jobAwaitingQuotes: Icons.request_quote_outlined,
    PricingConstants.jobQuoteSelected: Icons.fact_check_outlined,
    PricingConstants.jobPausedChangeOrder: Icons.pause_circle_outline,
    PricingConstants.jobAwaitingClientApproval: Icons.rate_review_outlined,
  };

  static bool isKnown(String status) => _labels.containsKey(status);

  static String label(String status) => _labels[status] ?? unknownLabel;

  /// Etiqueta en mayúsculas para chips compactos.
  static String chipLabel(String status) => label(status).toUpperCase();

  static IconData icon(String status) =>
      _icons[status] ?? Icons.info_outline;

  static Color color(String status) {
    switch (status) {
      case AppConstants.jobStatusPending:
      case PricingConstants.jobAwaitingQuotes:
        return AppColors.warning;
      case AppConstants.jobStatusAccepted:
      case AppConstants.jobStatusEnRoute:
      case PricingConstants.jobQuoteSelected:
      case PricingConstants.jobAwaitingClientApproval:
        return AppColors.brandOrange;
      case AppConstants.jobStatusInProgress:
      case PricingConstants.jobAwaitingPayment:
      case PricingConstants.jobPausedChangeOrder:
        return AppColors.brandOrangeDark;
      case AppConstants.jobStatusCompleted:
        return AppColors.success;
      case AppConstants.jobStatusCancelled:
      case AppConstants.jobStatusNoShow:
        return AppColors.error;
      default:
        return AppColors.grayMedium;
    }
  }
}
