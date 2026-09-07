import '../../../../core/database/models/change_order_model.dart';
import '../../../../core/database/models/dispute_model.dart';
import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/quote_proposal_model.dart';
import '../../../../core/database/repositories/change_order_repository.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/domain/pricing_constants.dart';
import '../../../../core/services/dispute_service.dart';
import '../../../../core/services/job_state_machine.dart';
import '../../../../core/services/quote_proposal_service.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/utils/open_quote_utils.dart';

/// Carga datos auxiliares del detalle de trabajo (sin UI).
class JobDetailLoader {
  JobDetailLoader({
    ChangeOrderRepository? changeOrderRepository,
    UserRepository? userRepository,
    JobStateMachine? stateMachine,
  })  : _changeOrderRepository =
            changeOrderRepository ?? ChangeOrderRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _stateMachine = stateMachine ?? JobStateMachine.instance;

  final ChangeOrderRepository _changeOrderRepository;
  final UserRepository _userRepository;
  final JobStateMachine _stateMachine;

  /// Transiciones válidas cacheadas para el estado actual del job.
  Future<Map<String, bool>> loadValidTransitions(JobModel job) async {
    final transitions = <String, bool>{};

    final possibleStatuses = [
      PricingConstants.jobAwaitingPayment,
      PricingConstants.jobAwaitingClientApproval,
      AppConstants.jobStatusAccepted,
      AppConstants.jobStatusInProgress,
      AppConstants.jobStatusCompleted,
      AppConstants.jobStatusCancelled,
      PricingConstants.jobPausedChangeOrder,
    ];

    for (final status in possibleStatuses) {
      final canTransition = _stateMachine.isValidTransition(
        job.status,
        status,
        pricingMode: job.pricingMode,
      );
      transitions[status] = canTransition;
    }

    return transitions;
  }

  Future<List<ChangeOrderModel>> loadChangeOrders(String jobId) {
    return _changeOrderRepository.getByJobId(jobId);
  }

  Future<DisputeModel?> loadDispute(String jobId) {
    return DisputeService.instance.getDisputeByJobId(jobId);
  }

  Future<List<QuoteProposalModel>> loadQuoteProposals(String jobId) {
    return QuoteProposalService.instance.listForJob(jobId);
  }

  Future<String?> loadInvitedWorkerName(JobModel job) async {
    final invitedId = OpenQuoteUtils.invitedWorkerId(job);
    if (invitedId == null) return null;
    final user = await _userRepository.getUserById(invitedId);
    return user?.name;
  }

  Future<String> loadAddress(JobModel job) async {
    try {
      return await LocationUtils.getLocationTextForJob(
        address: job.address,
        status: job.status,
        latitude: job.latitude,
        longitude: job.longitude,
      );
    } catch (_) {
      if (job.status == AppConstants.jobStatusPending) {
        return 'Ubicación aproximada';
      }
      return await LocationUtils.resolveExactAddress(
        address: job.address,
        latitude: job.latitude,
        longitude: job.longitude,
      );
    }
  }
}
