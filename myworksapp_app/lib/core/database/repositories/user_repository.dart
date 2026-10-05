import 'package:supabase_flutter/supabase_flutter.dart' show UserAttributes;
import '../../exceptions/auth_exceptions.dart';
import '../../utils/validators.dart';
import '../models/user_model.dart';
import '../supabase_db.dart';

/// Repositorio de usuarios sobre la tabla `perfiles` de Supabase.
///
/// La autenticación (email/contraseña) la maneja Supabase Auth; aquí solo se
/// gestiona el perfil público asociado a cada `auth.users.id`.
class UserRepository {
  static const String _table = 'perfiles';

  Future<String> createUser(UserModel user) async {
    // El perfil normalmente lo crea un trigger al registrarse en Supabase Auth.
    // Este upsert cubre el caso de completar/actualizar datos del propio perfil.
    final data = user.toMap()..remove('password');
    await supabase.from(_table).upsert(data);
    return user.id;
  }

  Future<UserModel?> getUserById(String id) async {
    final row = await supabase.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return UserModel.fromMap(row);
  }

  /// Nombre, rol y foto. Para catálogo, reseñas y fichas que no son la propia
  /// ni la de la contraparte de un trabajo.
  Future<Map<String, UserModel>> getPublicProfilesByIds(List<String> ids) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (unique.isEmpty) return {};
    final rows = await supabase.rpc(
      'perfiles_publicos_por_ids',
      params: {'p_ids': unique},
    );
    final out = <String, UserModel>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final model = UserModel.publicCard(map);
      out[model.id] = model;
    }
    return out;
  }

  Future<UserModel?> getPublicProfile(String id) async {
    final found = await getPublicProfilesByIds([id]);
    return found[id];
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final row = await supabase
        .from(_table)
        .select()
        .eq('correo', email.toLowerCase().trim())
        .maybeSingle();
    if (row == null) return null;
    return UserModel.fromMap(row);
  }

  Future<void> updateUser(UserModel user) async {
    final data = user.toMap()
      ..remove('password')
      ..remove('rol')
      ..remove('estado_cuenta');
    await supabase.from(_table).update(data).eq('id', user.id);
  }

  Future<void> updateProfilePhotoPath(String userId, String? photoPath) async {
    await supabase
        .from(_table)
        .update({'ruta_foto_perfil': photoPath}).eq('id', userId);
  }

  /// La contraseña la gestiona Supabase Auth; se mantiene por compatibilidad.
  Future<void> updatePassword(String userId, String passwordHash) async {
    final policyError = Validators.validateSecurePassword(passwordHash);
    if (policyError != null) throw WeakPasswordException(policyError);
    await supabase.auth.updateUser(UserAttributes(password: passwordHash));
  }

  Future<void> updateAccountStatus(String userId, String status) async {
    await supabase
        .from(_table)
        .update({'estado_cuenta': status}).eq('id', userId);
  }

  Future<void> deleteUser(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  Future<List<UserModel>> getAllUsers() async {
    final rows = await supabase.from(_table).select();
    return rows.map<UserModel>((m) => UserModel.fromMap(m)).toList();
  }
}
