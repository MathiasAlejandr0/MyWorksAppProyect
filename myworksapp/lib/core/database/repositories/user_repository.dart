import 'package:supabase_flutter/supabase_flutter.dart' show UserAttributes;
import '../models/user_model.dart';
import '../supabase_db.dart';

/// Repositorio de usuarios sobre la tabla `profiles` de Supabase.
///
/// La autenticación (email/contraseña) la maneja Supabase Auth; aquí solo se
/// gestiona el perfil público asociado a cada `auth.users.id`.
class UserRepository {
  static const String _table = 'profiles';

  Future<String> createUser(UserModel user) async {
    // El perfil normalmente lo crea un trigger al registrarse en Supabase Auth.
    // Este upsert cubre el caso de completar/actualizar datos del propio perfil.
    final data = user.toMap()..remove('password');
    await supabase.from(_table).upsert(data);
    return user.id;
  }

  Future<UserModel?> getUserById(String id) async {
    final row =
        await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return UserModel.fromMap(row);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('email', email.toLowerCase().trim())
        .maybeSingle();
    if (row == null) return null;
    return UserModel.fromMap(row);
  }

  Future<void> updateUser(UserModel user) async {
    final data = user.toMap()..remove('password');
    await supabase.from(_table).update(data).eq('id', user.id);
  }

  Future<void> updateProfilePhotoPath(String userId, String? photoPath) async {
    await supabase
        .from(_table)
        .update({'profilePhotoPath': photoPath}).eq('id', userId);
  }

  /// La contraseña la gestiona Supabase Auth; se mantiene por compatibilidad.
  Future<void> updatePassword(String userId, String passwordHash) async {
    await supabase.auth.updateUser(UserAttributes(password: passwordHash));
  }

  Future<void> updateAccountStatus(String userId, String status) async {
    await supabase
        .from(_table)
        .update({'accountStatus': status}).eq('id', userId);
  }

  Future<void> deleteUser(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  Future<List<UserModel>> getAllUsers() async {
    final rows = await supabase.from(_table).select();
    return rows.map<UserModel>((m) => UserModel.fromMap(m)).toList();
  }
}
