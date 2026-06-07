import '../models/user_consent_model.dart';
import '../supabase_db.dart';

/// Repositorio para gestionar consentimientos GDPR
class UserConsentRepository {
  static const String _table = 'user_consents';

  Future<void> createConsent(UserConsentModel consent) async {
    await supabase.from(_table).insert(consent.toMap());
  }

  Future<UserConsentModel?> getLatestConsent(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('userId', userId)
        .order('acceptedAt', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return UserConsentModel.fromMap(rows.first);
  }

  Future<bool> hasAcceptedCurrentVersion(
      String userId, String currentVersion) async {
    final latest = await getLatestConsent(userId);
    if (latest == null) return false;
    return latest.accepted && latest.consentVersion == currentVersion;
  }

  Future<List<UserConsentModel>> getUserConsents(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('userId', userId)
        .order('acceptedAt', ascending: false);
    return rows
        .map<UserConsentModel>((m) => UserConsentModel.fromMap(m))
        .toList();
  }

  Future<void> deleteUserConsents(String userId) async {
    await supabase.from(_table).delete().eq('userId', userId);
  }
}
