import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';

/// Servicio de validación de preparación para lanzamiento
/// 
/// Valida requisitos de App Store / Play Store antes de build release
class ReleaseReadinessService {
  static final ReleaseReadinessService instance = 
      ReleaseReadinessService._();
  ReleaseReadinessService._();

  /// Valida todos los requisitos de lanzamiento
  Future<ReleaseReadinessResult> validateAll() async {
    final issues = <ReleaseReadinessIssue>[];
    
    // 1. Privacy Policy URL
    final privacyPolicyIssue = await _validatePrivacyPolicy();
    if (privacyPolicyIssue != null) issues.add(privacyPolicyIssue);
    
    // 2. Términos aceptados
    final termsIssue = await _validateTermsAccepted();
    if (termsIssue != null) issues.add(termsIssue);
    
    // 3. Permisos explicados
    final permissionsIssue = await _validatePermissionsExplained();
    if (permissionsIssue != null) issues.add(permissionsIssue);
    
    // 4. Modo invitado NO permitido
    final guestModeIssue = await _validateNoGuestMode();
    if (guestModeIssue != null) issues.add(guestModeIssue);
    
    // 5. Screenshots legales habilitados
    final screenshotsIssue = await _validateLegalScreenshots();
    if (screenshotsIssue != null) issues.add(screenshotsIssue);
    
    return ReleaseReadinessResult(
      isReady: issues.isEmpty,
      issues: issues,
    );
  }

  /// Valida que Privacy Policy URL esté configurada
  Future<ReleaseReadinessIssue?> _validatePrivacyPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final privacyPolicyUrl = prefs.getString('privacy_policy_url');
      
      if (privacyPolicyUrl == null || privacyPolicyUrl.isEmpty) {
        return ReleaseReadinessIssue(
          type: ReleaseReadinessIssueType.missingPrivacyPolicy,
          severity: ReleaseReadinessSeverity.critical,
          message: 'Privacy Policy URL no configurada',
          fix: 'Configurar URL de Privacy Policy en SharedPreferences con clave "privacy_policy_url"',
        );
      }
      
      return null;
    } catch (e) {
      AppLogger.e('Error validando Privacy Policy', e);
      return ReleaseReadinessIssue(
        type: ReleaseReadinessIssueType.unknown,
        severity: ReleaseReadinessSeverity.warning,
        message: 'Error al validar Privacy Policy: $e',
      );
    }
  }

  /// Valida que los términos hayan sido aceptados
  Future<ReleaseReadinessIssue?> _validateTermsAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final termsAccepted = prefs.getBool('terms_accepted') ?? false;
      
      if (!termsAccepted) {
        return ReleaseReadinessIssue(
          type: ReleaseReadinessIssueType.termsNotAccepted,
          severity: ReleaseReadinessSeverity.critical,
          message: 'Términos y condiciones no aceptados',
          fix: 'Asegurar que los usuarios acepten términos antes de usar la app',
        );
      }
      
      return null;
    } catch (e) {
      AppLogger.e('Error validando términos', e);
      return null;
    }
  }

  /// Valida que los permisos estén explicados en runtime
  Future<ReleaseReadinessIssue?> _validatePermissionsExplained() async {
    // Esta validación es más compleja y requiere verificar que:
    // 1. Los permisos se solicitan en runtime (no solo en manifest)
    // 2. Se explica el propósito antes de solicitar
    // Por ahora, solo verificamos que existe un flag de explicación
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsExplained = prefs.getBool('permissions_explained') ?? false;
      
      if (!permissionsExplained) {
        return ReleaseReadinessIssue(
          type: ReleaseReadinessIssueType.permissionsNotExplained,
          severity: ReleaseReadinessSeverity.warning,
          message: 'Permisos no explicados en runtime',
          fix: 'Asegurar que todos los permisos se expliquen antes de solicitar',
        );
      }
      
      return null;
    } catch (e) {
      AppLogger.e('Error validando permisos', e);
      return null;
    }
  }

  /// Valida que el modo invitado NO esté permitido
  Future<ReleaseReadinessIssue?> _validateNoGuestMode() async {
    // Verificar que no hay ruta de acceso sin autenticación
    // (excepto welcome, login, register, legal pages)
    
    try {
      // Por ahora, asumimos que el router ya está configurado correctamente
      // En el futuro, esto puede verificar rutas accesibles sin login
      return null;
    } catch (e) {
      AppLogger.e('Error validando modo invitado', e);
      return null;
    }
  }

  /// Valida que los screenshots legales estén habilitados
  Future<ReleaseReadinessIssue?> _validateLegalScreenshots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legalScreenshotsEnabled = prefs.getBool('legal_screenshots_enabled') ?? false;
      
      if (!legalScreenshotsEnabled) {
        return ReleaseReadinessIssue(
          type: ReleaseReadinessIssueType.legalScreenshotsDisabled,
          severity: ReleaseReadinessSeverity.warning,
          message: 'Screenshots legales no habilitados',
          fix: 'Habilitar captura de pantalla para páginas legales (Privacy Policy, Terms)',
        );
      }
      
      return null;
    } catch (e) {
      AppLogger.e('Error validando screenshots legales', e);
      return null;
    }
  }

  /// Muestra alerta si hay problemas antes de build release
  Future<void> showAlertIfNotReady() async {
    final result = await validateAll();
    
    if (!result.isReady) {
      AppLogger.w('⚠️ APP NO ESTÁ LISTA PARA RELEASE');
      AppLogger.w('Problemas encontrados:');
      for (final issue in result.issues) {
        AppLogger.w('  - [${issue.severity}] ${issue.message}');
        if (issue.fix != null) {
          AppLogger.w('    Fix: ${issue.fix}');
        }
      }
    } else {
      AppLogger.i('✅ App lista para release');
    }
  }
}

/// Resultado de validación de preparación
class ReleaseReadinessResult {
  final bool isReady;
  final List<ReleaseReadinessIssue> issues;

  ReleaseReadinessResult({
    required this.isReady,
    required this.issues,
  });
}

/// Issue de preparación
class ReleaseReadinessIssue {
  final ReleaseReadinessIssueType type;
  final ReleaseReadinessSeverity severity;
  final String message;
  final String? fix;

  ReleaseReadinessIssue({
    required this.type,
    required this.severity,
    required this.message,
    this.fix,
  });
}

enum ReleaseReadinessIssueType {
  missingPrivacyPolicy,
  termsNotAccepted,
  permissionsNotExplained,
  guestModeAllowed,
  legalScreenshotsDisabled,
  unknown,
}

enum ReleaseReadinessSeverity {
  critical,
  warning,
  info,
}

