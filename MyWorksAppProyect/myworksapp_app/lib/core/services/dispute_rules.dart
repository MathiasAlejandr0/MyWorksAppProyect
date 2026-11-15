import '../utils/constants.dart';

/// Disputa que todavía congela el pago y la calificación.
bool disputeIsOpen(String? status) {
  return status == AppConstants.disputeStatusOpen ||
      status == AppConstants.disputeStatusUnderReview;
}
