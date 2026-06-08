import '../models/dispute_model.dart';
import '../models/user_model.dart';
import '../supabase_db.dart';

class AdminMetrics {
  final int usersCount;
  final int workersCount;
  final int jobsCount;
  final int openDisputesCount;
  final int reportsCount;

  const AdminMetrics({
    required this.usersCount,
    required this.workersCount,
    required this.jobsCount,
    required this.openDisputesCount,
    required this.reportsCount,
  });
}

class AdminRepository {
  Future<AdminMetrics> getMetrics() async {
    final users = await supabase.from('profiles').select('id');
    final workers = await supabase.from('workers').select('userId');
    final jobs = await supabase.from('jobs').select('id');
    final disputes = await supabase
        .from('disputes')
        .select('id')
        .eq('status', 'open');
    final reports = await supabase.from('reports').select('id');

    return AdminMetrics(
      usersCount: (users as List).length,
      workersCount: (workers as List).length,
      jobsCount: (jobs as List).length,
      openDisputesCount: (disputes as List).length,
      reportsCount: (reports as List).length,
    );
  }

  Future<List<UserModel>> listUsers({int limit = 100}) async {
    final rows = await supabase
        .from('profiles')
        .select()
        .order('createdAt', ascending: false)
        .limit(limit);
    return rows
        .map<UserModel>((m) => UserModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> updateAccountStatus(String userId, String status) async {
    await supabase
        .from('profiles')
        .update({'accountStatus': status}).eq('id', userId);
  }

  Future<List<DisputeModel>> listDisputes({String? status}) async {
    var query = supabase.from('disputes').select();
    if (status != null) {
      query = query.eq('status', status);
    }
    final rows = await query.order('createdAt', ascending: false);
    return rows
        .map<DisputeModel>((m) => DisputeModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }
}
