import '../domain/pricing_constants.dart';
import '../utils/constants.dart';

/// Transiciones válidas de [JobModel.status] según [pricing_mode].
class JobTransitionMatrix {
  JobTransitionMatrix._();

  static const _legacy = {
    AppConstants.jobStatusPending: [
      AppConstants.jobStatusAccepted,
      AppConstants.jobStatusCancelled,
      AppConstants.jobStatusExpired,
    ],
    AppConstants.jobStatusAccepted: [
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCancelled,
      AppConstants.jobStatusPending,
    ],
    AppConstants.jobStatusInProgress: [
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
      AppConstants.jobStatusNoShow,
      PricingConstants.jobPausedChangeOrder,
    ],
    AppConstants.jobStatusCompleted: <String>[],
    AppConstants.jobStatusCancelled: <String>[],
    AppConstants.jobStatusExpired: <String>[],
    AppConstants.jobStatusNoShow: <String>[],
    PricingConstants.jobPausedChangeOrder: [
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCancelled,
    ],
  };

  static const _escrowPreWork = {
    PricingConstants.jobAwaitingPayment: [
      AppConstants.jobStatusAccepted,
      AppConstants.jobStatusCancelled,
    ],
    AppConstants.jobStatusAccepted: [
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCancelled,
    ],
  };

  static Map<String, List<String>> forMode(String pricingMode) {
    switch (pricingMode) {
      case PricingConstants.modeFixedPrice:
      case PricingConstants.modeHourlyBlock:
        return {
          ..._escrowPreWork,
          AppConstants.jobStatusInProgress: [
            AppConstants.jobStatusCompleted,
            AppConstants.jobStatusCancelled,
            AppConstants.jobStatusNoShow,
            PricingConstants.jobPausedChangeOrder,
          ],
          AppConstants.jobStatusCompleted: <String>[],
          AppConstants.jobStatusCancelled: <String>[],
          AppConstants.jobStatusNoShow: <String>[],
          PricingConstants.jobPausedChangeOrder: [
            AppConstants.jobStatusInProgress,
            AppConstants.jobStatusCancelled,
          ],
        };
      case PricingConstants.modeOpenQuote:
        return {
          PricingConstants.jobAwaitingQuotes: [
            PricingConstants.jobQuoteSelected,
            AppConstants.jobStatusCancelled,
            AppConstants.jobStatusExpired,
          ],
          PricingConstants.jobQuoteSelected: [
            PricingConstants.jobAwaitingPayment,
            AppConstants.jobStatusCancelled,
          ],
          ..._escrowPreWork,
          AppConstants.jobStatusInProgress: [
            AppConstants.jobStatusCompleted,
            AppConstants.jobStatusCancelled,
            AppConstants.jobStatusNoShow,
            PricingConstants.jobPausedChangeOrder,
          ],
          AppConstants.jobStatusCompleted: <String>[],
          AppConstants.jobStatusCancelled: <String>[],
          AppConstants.jobStatusExpired: <String>[],
          AppConstants.jobStatusNoShow: <String>[],
          PricingConstants.jobPausedChangeOrder: [
            AppConstants.jobStatusInProgress,
            AppConstants.jobStatusCancelled,
          ],
        };
      case PricingConstants.modeLegacy:
      default:
        return _legacy;
    }
  }

  static bool isAllowed(String pricingMode, String from, String to) {
    final map = forMode(pricingMode);
    final allowed = map[from];
    if (allowed == null) return false;
    return allowed.contains(to);
  }

  static List<String> allowedTargets(String pricingMode, String from) {
    return List.unmodifiable(forMode(pricingMode)[from] ?? []);
  }
}
