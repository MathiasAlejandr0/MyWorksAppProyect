import '../models/password_reset_code_model.dart';
import '../supabase_db.dart';
import 'package:uuid/uuid.dart';

/// Códigos de recuperación de contraseña.
///
/// Nota: con Supabase Auth la recuperación se gestiona vía email/OTP de
/// Supabase. Este repositorio se mantiene por compatibilidad del flujo previo.
class PasswordResetRepository {
  static const String _table = 'password_reset_codes';

  Future<String> createResetCode({
    required String userId,
    required String email,
    required String code,
  }) async {
    final id = const Uuid().v4();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    final resetCode = PasswordResetCodeModel(
      id: id,
      userId: userId,
      code: code,
      email: email,
      expiresAt: expiresAt,
      isUsed: false,
      createdAt: DateTime.now(),
    );

    await supabase.from(_table).insert(resetCode.toMap());
    return id;
  }

  Future<PasswordResetCodeModel?> validateCode({
    required String email,
    required String code,
  }) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('email', email.toLowerCase().trim())
        .eq('code', code)
        .eq('isUsed', 0)
        .order('createdAt', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;

    final resetCode = PasswordResetCodeModel.fromMap(rows.first);
    if (resetCode.isExpired) return null;
    return resetCode;
  }

  Future<void> markCodeAsUsed(String codeId) async {
    await supabase.from(_table).update({'isUsed': 1}).eq('id', codeId);
  }

  Future<void> deleteExpiredCodes() async {
    final now = DateTime.now().toIso8601String();
    await supabase.from(_table).delete().lt('expiresAt', now);
  }

  Future<void> invalidateUserCodes(String userId) async {
    await supabase
        .from(_table)
        .delete()
        .eq('userId', userId)
        .eq('isUsed', 0);
  }
}
