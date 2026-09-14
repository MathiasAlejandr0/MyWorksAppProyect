/// Modalidades de cobro y estados operativos extendidos (códigos BD en español).
class PricingConstants {
  PricingConstants._();

  static const String modeLegacy = 'legado';
  static const String modeFixedPrice = 'precio_fijo';
  static const String modeHourlyBlock = 'bloque_horas';
  static const String modeOpenQuote = 'cotizacion_abierta';

  static const List<String> allModes = [
    modeLegacy,
    modeFixedPrice,
    modeHourlyBlock,
    modeOpenQuote,
  ];

  static const String jobAwaitingPayment = 'esperando_pago';
  static const String jobAwaitingQuotes = 'esperando_cotizaciones';
  static const String jobQuoteSelected = 'cotizacion_seleccionada';
  static const String jobPausedChangeOrder = 'pausado_orden_cambio';
  static const String jobAwaitingClientApproval = 'esperando_aprobacion_cliente';

  static const String paymentNone = 'ninguno';
  static const String paymentPending = 'pendiente';
  static const String paymentAuthorized = 'autorizado';
  static const String paymentHeld = 'retenido';
  static const String paymentReleased = 'liberado';
  static const String paymentRefunded = 'reembolsado';

  static const String paymentTypePrimary = 'principal';
  static const String paymentTypeChangeOrder = 'orden_cambio';
  static const String paymentTypeOvertime = 'horas_extra';

  static const String changeOrderPending = 'pendiente_cliente';
  static const String changeOrderApproved = 'aprobada';
  static const String changeOrderRejected = 'rechazada';
  static const String changeOrderPaid = 'pagada';
  static const String changeOrderCancelled = 'cancelada';

  static const String quoteSubmitted = 'enviada';
  static const String quoteWithdrawn = 'retirada';
  static const String quoteAccepted = 'aceptada';
  static const String quoteRejected = 'rechazada';
}
