import '../database/models/payment_model.dart';
import '../database/repositories/change_order_repository.dart';
import '../database/repositories/job_photo_repository.dart';
import 'payment_service.dart';

Future<int> _evidenciaPresente(String jobId) async => 1;

/// Puertos inyectables para validar pagos en transiciones de trabajo (tests / producción).
///
/// No confundir con [PaymentGatewayPort] (`payment_gateway_port.dart`), que
/// modela la autorización/hold contra un PSP externo (Webpay/MP).
class PaymentGuardPorts {
  final Future<PaymentModel?> Function(String jobId) getPrimaryPayment;
  final Future<bool> Function(String jobId) hasAuthorizedPrimaryPayment;
  final Future<int> Function(String jobId) countPendingChangeOrders;
  final Future<int> Function(String jobId) countApprovedUnpaidChangeOrders;
  final Future<int> Function(String jobId) countEvidence;

  const PaymentGuardPorts({
    required this.getPrimaryPayment,
    required this.hasAuthorizedPrimaryPayment,
    required this.countPendingChangeOrders,
    required this.countApprovedUnpaidChangeOrders,
    this.countEvidence = _evidenciaPresente,
  });

  factory PaymentGuardPorts.production() {
    final changeOrders = ChangeOrderRepository();
    return PaymentGuardPorts(
      getPrimaryPayment: PaymentService.instance.getPrimaryPayment,
      hasAuthorizedPrimaryPayment:
          PaymentService.instance.hasAuthorizedPrimaryPayment,
      countPendingChangeOrders: changeOrders.countPendingClient,
      countApprovedUnpaidChangeOrders: changeOrders.countApprovedUnpaid,
      countEvidence: JobPhotoRepository().getEvidenceCountByJobId,
    );
  }
}
