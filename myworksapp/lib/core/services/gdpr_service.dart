import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../database/repositories/user_repository.dart';
import '../database/repositories/user_consent_repository.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/message_repository.dart';
import '../database/repositories/rating_repository.dart';
import '../database/models/user_consent_model.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';
import 'account_deletion_service.dart';

/// Servicio para cumplimiento GDPR
/// 
/// Maneja:
/// - Consentimiento explícito de usuarios
/// - Exportación de datos personales (JSON)
/// - Solicitud de eliminación de cuenta
/// - Verificación de consentimientos
class GdprService {
  static final GdprService instance = GdprService._();
  GdprService._();

  final UserRepository _userRepository = UserRepository();
  final UserConsentRepository _consentRepository = UserConsentRepository();
  final JobRepository _jobRepository = JobRepository();
  final MessageRepository _messageRepository = MessageRepository();
  final RatingRepository _ratingRepository = RatingRepository();

  // Versión actual de los términos y condiciones
  static const String currentConsentVersion = '1.0';

  /// Registra el consentimiento explícito de un usuario
  /// 
  /// Requerido para cumplimiento GDPR.
  /// Debe llamarse durante el registro o cuando se actualicen los términos.
  Future<void> recordConsent({
    required String userId,
    required bool accepted,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      AppLogger.i('Registrando consentimiento GDPR para usuario: $userId');

      if (!accepted) {
        throw AppError.validation('El consentimiento es obligatorio para usar la aplicación');
      }

      final consent = UserConsentModel(
        id: const Uuid().v4(),
        userId: userId,
        consentVersion: currentConsentVersion,
        accepted: accepted,
        acceptedAt: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      await _consentRepository.createConsent(consent);
      AppLogger.i('Consentimiento registrado exitosamente');
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al registrar consentimiento', e);
      throw AppError.database('Error al registrar consentimiento: ${e.toString()}');
    }
  }

  /// Verifica si un usuario ha aceptado la versión actual de los términos
  Future<bool> hasAcceptedCurrentTerms(String userId) async {
    try {
      return await _consentRepository.hasAcceptedCurrentVersion(
        userId,
        currentConsentVersion,
      );
    } catch (e) {
      AppLogger.e('Error al verificar consentimiento', e);
      return false;
    }
  }

  /// Exporta todos los datos personales de un usuario en formato JSON
  /// 
  /// Cumple con GDPR Artículo 15 (Derecho de acceso).
  /// Retorna un Map que puede serializarse a JSON.
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      AppLogger.i('Exportando datos personales para usuario: $userId');

      // Obtener datos del usuario
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw AppError.notFound('Usuario no encontrado');
      }

      // Obtener consentimientos
      final consents = await _consentRepository.getUserConsents(userId);

      // Obtener trabajos
      final jobs = await _jobRepository.getJobsByUserId(userId);

      // Obtener mensajes
      final messages = await _messageRepository.getMessagesByUserId(userId);

      // Obtener calificaciones
      final ratings = await _ratingRepository.getRatingsByUserId(userId);

      // Construir objeto de exportación
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'userData': {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'role': user.role,
          'accountStatus': user.accountStatus,
          'createdAt': user.createdAt.toIso8601String(),
          // NO incluir password hash por seguridad
        },
        'consents': consents.map((c) => {
          'version': c.consentVersion,
          'accepted': c.accepted,
          'acceptedAt': c.acceptedAt.toIso8601String(),
        }).toList(),
        'jobs': jobs.map((j) => {
          'id': j.id,
          'serviceId': j.serviceId,
          'status': j.status,
          'address': j.address,
          'description': j.description,
          'scheduledDate': j.scheduledDate?.toIso8601String(),
          'createdAt': j.createdAt.toIso8601String(),
          'updatedAt': j.updatedAt.toIso8601String(),
        }).toList(),
        'messages': messages.map((m) => {
          'id': m.id,
          'jobId': m.jobId,
          'content': m.content,
          'type': m.type,
          'isRead': m.isRead,
          'createdAt': m.createdAt.toIso8601String(),
        }).toList(),
        'ratings': ratings.map((r) => {
          'id': r.id,
          'jobId': r.jobId,
          'score': r.score,
          'comment': r.comment,
          'createdAt': r.createdAt.toIso8601String(),
        }).toList(),
      };

      AppLogger.i('Datos exportados exitosamente');
      return exportData;
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al exportar datos', e);
      throw AppError.database('Error al exportar datos: ${e.toString()}');
    }
  }

  /// Exporta datos en formato JSON string
  /// 
  /// Útil para guardar en archivo o enviar por email.
  Future<String> exportUserDataAsJson(String userId) async {
    final data = await exportUserData(userId);
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// Solicita eliminación de cuenta (GDPR Artículo 17 - Derecho al olvido)
  /// 
  /// Procesa la eliminación completa mediante AccountDeletionService.
  Future<void> requestAccountDeletion(String userId) async {
    try {
      AppLogger.i('Solicitando eliminación de cuenta para usuario: $userId');

      // Verificar que el usuario existe
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw AppError.notFound('Usuario no encontrado');
      }

      // Ejecutar eliminación completa
      final success = await AccountDeletionService.instance.deleteAccount(userId);
      
      if (!success) {
        throw AppError.database('No se pudo eliminar la cuenta');
      }

      AppLogger.i('Cuenta eliminada exitosamente');
    } catch (e) {
      if (e is AppError) {
        rethrow;
      }
      AppLogger.e('Error al solicitar eliminación', e);
      throw AppError.database('Error al solicitar eliminación: ${e.toString()}');
    }
  }

  /// Obtiene el historial de consentimientos de un usuario
  Future<List<UserConsentModel>> getConsentHistory(String userId) async {
    try {
      return await _consentRepository.getUserConsents(userId);
    } catch (e) {
      AppLogger.e('Error al obtener historial de consentimientos', e);
      return [];
    }
  }
}

