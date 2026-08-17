import '../../models/user_model.dart';
import '../../supabase_db.dart';

class AdminUsersRepository {
  Future<List<UserModel>> listUsers({
    int limit = 100,
    String? role,
    String? search,
    String? accountStatus,
  }) async {
    var query = supabase.from('profiles').select();
    if (role != null) {
      query = query.eq('role', role);
    }
    if (accountStatus != null) {
      query = query.eq('accountStatus', accountStatus);
    }
    if (search != null && search.isNotEmpty) {
      final q = '%$search%';
      query = query.or('name.ilike.$q,email.ilike.$q');
    }
    final rows =
        await query.order('createdAt', ascending: false).limit(limit);
    return rows
        .map<UserModel>((m) => UserModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> updateAccountStatus(String userId, String status) async {
    await supabase
        .from('profiles')
        .update({'accountStatus': status}).eq('id', userId);
  }
}
