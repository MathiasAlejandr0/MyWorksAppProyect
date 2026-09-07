// GENERATED CODE - do not edit by hand.
// Source: shared/src/domain.ts
// Regenerate: node scripts/generate-domain-dart.mjs
// ignore_for_file: public_member_api_docs

/// Roles - generated from shared/src/domain.ts
class GeneratedUserRoles {
  GeneratedUserRoles._();

  static const String user = 'user';
  static const String worker = 'worker';
  static const String admin = 'admin';
}

/// Job statuses - generated from shared/src/domain.ts
class GeneratedJobStatuses {
  GeneratedJobStatuses._();

  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String expired = 'expired';
  static const String noShow = 'no_show';
  static const String awaitingPayment = 'awaiting_payment';
  static const String awaitingQuotes = 'awaiting_quotes';
  static const String quoteSelected = 'quote_selected';
  static const String pausedChangeOrder = 'paused_change_order';
  static const String awaitingClientApproval = 'awaiting_client_approval';
}

/// Payment statuses - generated from shared/src/domain.ts
class GeneratedPaymentStatuses {
  GeneratedPaymentStatuses._();

  static const String none = 'none';
  static const String pending = 'pending';
  static const String authorized = 'authorized';
  static const String held = 'held';
  static const String released = 'released';
  static const String refunded = 'refunded';
}

/// Pricing modes - generated from shared/src/domain.ts
class GeneratedPricingModes {
  GeneratedPricingModes._();

  static const String legacy = 'legacy';
  static const String fixedPrice = 'fixed_price';
  static const String hourlyBlock = 'hourly_block';
  static const String openQuote = 'open_quote';
}

/// Dispute statuses - generated from shared/src/domain.ts
class GeneratedDisputeStatuses {
  GeneratedDisputeStatuses._();

  static const String open = 'open';
  static const String underReview = 'under_review';
  static const String resolved = 'resolved';
}

/// Active job statuses for workers (mirror of TS WORKER_ACTIVE_JOB_STATUSES).
class GeneratedWorkerActiveJobStatuses {
  GeneratedWorkerActiveJobStatuses._();

  static const List<String> values = [
    'accepted',
    'in_progress',
    'awaiting_client_approval',
    'awaiting_payment',
    'paused_change_order',
    'quote_selected',
  ];

  static bool contains(String status) => values.contains(status);
}
