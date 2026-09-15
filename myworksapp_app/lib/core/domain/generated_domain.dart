// GENERATED CODE - do not edit by hand.
// Source: shared/src/domain.ts
// Regenerate: node scripts/generate-domain-dart.mjs
// ignore_for_file: public_member_api_docs

/// Roles - generated from shared/src/domain.ts
class GeneratedUserRoles {
  GeneratedUserRoles._();

  static const String user = 'usuario';
  static const String worker = 'trabajador';
  static const String admin = 'administrador';
}

/// Job statuses - generated from shared/src/domain.ts
class GeneratedJobStatuses {
  GeneratedJobStatuses._();

  static const String pending = 'pendiente';
  static const String accepted = 'aceptado';
  static const String inProgress = 'en_curso';
  static const String completed = 'completado';
  static const String cancelled = 'cancelado';
  static const String expired = 'expirado';
  static const String noShow = 'no_asistio';
  static const String awaitingPayment = 'esperando_pago';
  static const String awaitingQuotes = 'esperando_cotizaciones';
  static const String quoteSelected = 'cotizacion_seleccionada';
  static const String pausedChangeOrder = 'pausado_orden_cambio';
  static const String awaitingClientApproval = 'esperando_aprobacion_cliente';
}

/// Payment statuses - generated from shared/src/domain.ts
class GeneratedPaymentStatuses {
  GeneratedPaymentStatuses._();

  static const String none = 'ninguno';
  static const String pending = 'pendiente';
  static const String authorized = 'autorizado';
  static const String held = 'retenido';
  static const String released = 'liberado';
  static const String refunded = 'reembolsado';
}

/// Pricing modes - generated from shared/src/domain.ts
class GeneratedPricingModes {
  GeneratedPricingModes._();

  static const String legacy = 'legado';
  static const String fixedPrice = 'precio_fijo';
  static const String hourlyBlock = 'bloque_horas';
  static const String openQuote = 'cotizacion_abierta';
}

/// Dispute statuses - generated from shared/src/domain.ts
class GeneratedDisputeStatuses {
  GeneratedDisputeStatuses._();

  static const String open = 'abierta';
  static const String underReview = 'en_revision';
  static const String resolved = 'resuelta';
}

/// Active job statuses for workers (mirror of TS WORKER_ACTIVE_JOB_STATUSES).
class GeneratedWorkerActiveJobStatuses {
  GeneratedWorkerActiveJobStatuses._();

  static const List<String> values = [
    'aceptado',
    'en_curso',
    'esperando_aprobacion_cliente',
    'esperando_pago',
    'pausado_orden_cambio',
    'cotizacion_seleccionada',
  ];

  static bool contains(String status) => values.contains(status);
}
