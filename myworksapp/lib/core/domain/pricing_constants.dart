/// Modalidades de cobro (Angi-style) y estados operativos extendidos.
class PricingConstants {
  PricingConstants._();

  // —— Modalidades ——
  /// Flujo histórico sin escrow obligatorio (jobs existentes).
  static const String modeLegacy = 'legacy';
  static const String modeFixedPrice = 'fixed_price';
  static const String modeHourlyBlock = 'hourly_block';
  static const String modeOpenQuote = 'open_quote';

  static const List<String> allModes = [
    modeLegacy,
    modeFixedPrice,
    modeHourlyBlock,
    modeOpenQuote,
  ];

  // —— Estados operativos adicionales ——
  static const String jobAwaitingPayment = 'awaiting_payment';
  static const String jobAwaitingQuotes = 'awaiting_quotes';
  static const String jobQuoteSelected = 'quote_selected';
  static const String jobPausedChangeOrder = 'paused_change_order';

  // —— payment_status denormalizado en jobs ——
  static const String paymentNone = 'none';
  static const String paymentPending = 'pending';
  static const String paymentAuthorized = 'authorized';
  static const String paymentHeld = 'held';
  static const String paymentReleased = 'released';
  static const String paymentRefunded = 'refunded';

  // —— Tipos de pago ——
  static const String paymentTypePrimary = 'primary';
  static const String paymentTypeChangeOrder = 'change_order';
  static const String paymentTypeOvertime = 'overtime';

  // —— Change orders ——
  static const String changeOrderPending = 'pending_client';
  static const String changeOrderApproved = 'approved';
  static const String changeOrderRejected = 'rejected';
  static const String changeOrderPaid = 'paid';
  static const String changeOrderCancelled = 'cancelled';

  // —— Cotizaciones ——
  static const String quoteSubmitted = 'submitted';
  static const String quoteWithdrawn = 'withdrawn';
  static const String quoteAccepted = 'accepted';
  static const String quoteRejected = 'rejected';
}
