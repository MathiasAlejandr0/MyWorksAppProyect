import 'package:uuid/uuid.dart';
import '../database/repositories/report_repository.dart';
import '../database/repositories/user_repository.dart';
import '../database/models/report_model.dart';
import '../utils/app_logger.dart';

/// Servicio para manejar reportes y bloqueos
class ReportService {
  final ReportRepository _reportRepository = ReportRepository();
  final UserRepository _userRepository = UserRepository();

  /// Crea un reporte de usuario/trabajador
  Future<bool> createReport({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      // Validar que el motivo no esté vacío
      if (reason.trim().isEmpty) {
        AppLogger.w('Motivo de reporte vacío');
        return false;
      }

      // Crear reporte
      final report = ReportModel(
        id: const Uuid().v4(),
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason.trim(),
        description: description?.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _reportRepository.createReport(report);

      // Si hay múltiples reportes, cambiar estado a suspended
      final reports = await _reportRepository.getReportsByReportedUserId(reportedUserId);
      if (reports.length >= 3) {
        // 3 o más reportes: suspender cuenta
        await _userRepository.updateAccountStatus(reportedUserId, 'suspended');
        AppLogger.i('Cuenta suspendida por múltiples reportes: $reportedUserId');
      }

      AppLogger.i('Reporte creado exitosamente');
      return true;
    } catch (e) {
      AppLogger.e('Error al crear reporte', e);
      return false;
    }
  }

  /// Obtiene los reportes de un usuario
  Future<List<ReportModel>> getReportsByReporter(String reporterId) async {
    try {
      return await _reportRepository.getReportsByReporterId(reporterId);
    } catch (e) {
      AppLogger.e('Error al obtener reportes', e);
      return [];
    }
  }

  /// Obtiene los reportes sobre un usuario
  Future<List<ReportModel>> getReportsAboutUser(String reportedUserId) async {
    try {
      return await _reportRepository.getReportsByReportedUserId(reportedUserId);
    } catch (e) {
      AppLogger.e('Error al obtener reportes sobre usuario', e);
      return [];
    }
  }
}

