import '../database/models/payment_model.dart';
import '../database/repositories/change_order_repository.dart';
import 'payment_service.dart';

/// Puertos inyectables para validar pagos en transiciones de trabajo (tests / producción).
class PaymentGuardPorts {
  final Future<PaymentModel?> Function(String jobId) getPrimaryPayment;
  final Future<bool> Function(String jobId) hasAuthorizedPrimaryPayment;
  final Future<int> Function(String jobId) countPendingChangeOrders;
  final Future<int> Function(String jobId) countApprovedUnpaidChangeOrders;

  const PaymentGuardPorts({
    required this.getPrimaryPayment,
    required this.hasAuthorizedPrimaryPayment,
    required this.countPendingChangeOrders,
    required this.countApprovedUnpaidChangeOrders,
  });

  factory PaymentGuardPorts.production() {
    final changeOrders = ChangeOrderRepository();
    return PaymentGuardPorts(
      getPrimaryPayment: PaymentService.instance.getPrimaryPayment,
      hasAuthorizedPrimaryPayment:
          PaymentService.instance.hasAuthorizedPrimaryPayment,
      countPendingChangeOrders: changeOrders.countPendingClient,
      countApprovedUnpaidChangeOrders: changeOrders.countApprovedUnpaid,
    );
  }
}
