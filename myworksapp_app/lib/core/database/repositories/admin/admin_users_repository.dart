import '../../models/user_model.dart';
import '../../supabase_db.dart';

class AdminUsersRepository {
  Future<List<UserModel>> listUsers({
    int limit = 100,
    String? role,
    String? search,
    String? accountStatus,
  }) async {
    var query = supabase.from('perfiles').select();
    if (role != null) {
      query = query.eq('rol', role);
    }
    if (accountStatus != null) {
      query = query.eq('estado_cuenta', accountStatus);
    }
    if (search != null && search.isNotEmpty) {
      final q = '%$search%';
      query = query.or('nombre.ilike.$q,correo.ilike.$q');
    }
    final rows = await query.order('creado_en', ascending: false).limit(limit);
    return rows
        .map<UserModel>((m) => UserModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> updateAccountStatus(String userId, String status) async {
    await supabase
        .from('perfiles')
        .update({'estado_cuenta': status}).eq('id', userId);
  }
}
