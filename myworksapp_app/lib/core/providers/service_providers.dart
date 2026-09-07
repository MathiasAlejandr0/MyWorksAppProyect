import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/job_booking_service.dart';
import '../services/job_state_machine.dart';
import '../services/payment_service.dart';
import 'repository_providers.dart';

/// DI de [JobBookingService] sobre repos / state machine compartidos.
///
/// Preferir este provider en widgets/controllers con [Ref].
/// Call sites sin Ref (p. ej. lógica legacy) pueden seguir usando
/// [JobBookingService.instance] hasta migrarlos.
final jobBookingServiceProvider = Provider<JobBookingService>((ref) {
  return JobBookingService(
    jobs: ref.watch(jobRepositoryProvider),
    stateMachine: JobStateMachine.instance,
  );
});

/// DI de [PaymentService] sobre repos de [repository_providers].
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    paymentRepository: ref.watch(paymentRepositoryProvider),
    jobRepository: ref.watch(jobRepositoryProvider),
  );
});
