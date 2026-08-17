import '../models/subscription_model.dart';
import '../supabase_db.dart';

class SubscriptionRepository {
  static const String _table = 'subscriptions';

  Future<void> createSubscription(SubscriptionModel subscription) async {
    await supabase.from(_table).insert(subscription.toMap());
  }

  Future<SubscriptionModel?> getSubscriptionById(String id) async {
    final row =
        await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return SubscriptionModel.fromMap(row);
  }

  Future<SubscriptionModel?> getActiveSubscription(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('userId', userId)
        .eq('status', 'active')
        .order('startDate', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return SubscriptionModel.fromMap(rows.first);
  }

  Future<List<SubscriptionModel>> getActiveSubscriptions() async {
    final rows =
        await supabase.from(_table).select().eq('status', 'active');
    return rows
        .map<SubscriptionModel>((m) => SubscriptionModel.fromMap(m))
        .toList();
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    await supabase
        .from(_table)
        .update(subscription.toMap())
        .eq('id', subscription.id);
  }
}
