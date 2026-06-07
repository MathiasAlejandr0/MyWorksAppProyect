import '../models/change_order_model.dart';
import '../supabase_db.dart';
import '../../domain/pricing_constants.dart';

class ChangeOrderRepository {
  static const String _table = 'change_orders';

  Future<void> create(ChangeOrderModel order) async {
    await supabase.from(_table).insert(order.toMap());
  }

  Future<List<ChangeOrderModel>> getByJobId(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('jobId', jobId)
        .order('createdAt', ascending: false);
    return rows.map<ChangeOrderModel>((m) => ChangeOrderModel.fromMap(m)).toList();
  }

  Future<int> countPendingClient(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select('id')
        .eq('jobId', jobId)
        .eq('estado', PricingConstants.changeOrderPending);
    return rows.length;
  }

  Future<int> countApprovedUnpaid(String jobId) async {
    final rows = await supabase
        .from(_table)
        .select('id')
        .eq('jobId', jobId)
        .eq('estado', PricingConstants.changeOrderApproved);
    return rows.length;
  }

  Future<void> update(ChangeOrderModel order) async {
    await supabase.from(_table).update(order.toMap()).eq('id', order.id);
  }
}
