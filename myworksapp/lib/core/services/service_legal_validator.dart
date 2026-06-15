import 'package:intl/intl.dart';

import '../database/models/service_model.dart';
import '../database/repositories/service_repository.dart';
import '../utils/app_logger.dart';
/// Validador legal de servicios para Chile
/// 
/// Asegura que los servicios cumplan con:
/// - No requieran certificación profesional regulada
/// - No generen responsabilidad laboral
/// - Operen como intermediación tecnológica
class ServiceLegalValidator {
  static final ServiceLegalValidator instance = ServiceLegalValidator._();
  ServiceLegalValidator._();

  final ServiceRepository _serviceRepository = ServiceRepository();

  /// Declaración legal obligatoria
  static const String platformDisclaimer = 
      'My Works App actúa únicamente como intermediario tecnológico entre usuarios '
      'y trabajadores independientes. No presta servicios profesionales ni técnicos '
      'regulados. La plataforma no asume responsabilidad por la calidad, resultado '
      'o cumplimiento de los servicios prestados por trabajadores independientes.';

  /// Valida que un servicio sea legalmente viable en Chile
  Future<ValidationResult> validateService(String serviceId) async {
    try {
      final service = await _serviceRepository.getServiceById(serviceId);
      if (service == null) {
        return ValidationResult(
          valid: false,
          reason: 'Servicio no encontrado',
        );
      }

      // 1. Verificar que no requiera certificación
      if (service.requiresCertification) {
        return ValidationResult(
          valid: false,
          reason: 'Este servicio requiere certificación profesional regulada y no está disponible en la plataforma',
        );
      }

      // 2. Verificar que esté activo
      if (!service.isActive) {
        return ValidationResult(
          valid: false,
          reason: 'Este servicio no está disponible actualmente',
        );
      }

      // 3. Validaciones específicas por categoría
      final categoryValidation = _validateCategory(service.category);
      if (!categoryValidation.valid) {
        return categoryValidation;
      }

      return ValidationResult(valid: true);
    } catch (e) {
      AppLogger.e('Error validando servicio legalmente', e);
      return ValidationResult(
        valid: false,
        reason: 'Error al validar servicio',
      );
    }
  }

  /// Valida categoría específica
  ValidationResult _validateCategory(String category) {
    switch (category) {
      case ServiceCategories.cleaning:
        // Limpieza domiciliaria: ✅ Permitido
        return ValidationResult(valid: true);

      case ServiceCategories.assembly:
        // Armado de muebles: ✅ Permitido
        return ValidationResult(valid: true);

      case ServiceCategories.techSupport:
        // Soporte técnico básico: ✅ Permitido (NO telecomunicaciones)
        return ValidationResult(valid: true);

      case ServiceCategories.gardening:
        // Jardinería básica: ✅ Permitido
        return ValidationResult(valid: true);

      case ServiceCategories.moving:
        // Mudanzas pequeñas: ⚠️ Permitido con restricciones
        return ValidationResult(
          valid: true,
          warning: 'Solo mudanzas pequeñas dentro de la ciudad. No transporte comercial ni internacional.',
        );

      case ServiceCategories.construction:
      case ServiceCategories.plumbing:
      case ServiceCategories.electrical:
        // Servicios existentes: ✅ Permitidos (ya validados previamente)
        return ValidationResult(valid: true);

      default:
        return ValidationResult(
          valid: false,
          reason: 'Categoría de servicio no reconocida',
        );
    }
  }

  /// Valida restricciones específicas de un servicio
  Future<ValidationResult> validateServiceRestrictions({
    required String serviceId,
    Map<String, dynamic>? serviceData,
  }) async {
    try {
      final service = await _serviceRepository.getServiceById(serviceId);
      if (service == null) {
        return ValidationResult(valid: false, reason: 'Servicio no encontrado');
      }

      // Validaciones específicas por servicio
      switch (service.category) {
        case ServiceCategories.techSupport:
          // Verificar que no incluya servicios regulados
          final problem = serviceData?['problem'] as String? ?? '';
          if (_isRegulatedTechService(problem)) {
            return ValidationResult(
              valid: false,
              reason: 'Este tipo de servicio técnico requiere certificación profesional y no está disponible',
            );
          }
          break;

        case ServiceCategories.gardening:
          // Verificar que no incluya tala de árboles grandes
          final task = serviceData?['task'] as String? ?? '';
          if (task.toLowerCase().contains('tala') || 
              task.toLowerCase().contains('árbol grande')) {
            return ValidationResult(
              valid: false,
              reason: 'La tala de árboles grandes requiere permisos especiales y no está disponible',
            );
          }
          break;

        case ServiceCategories.moving:
          // Verificar que sea mudanza pequeña
          final volume = serviceData?['volume'] as String? ?? '';
          if (volume.toLowerCase().contains('comercial') ||
              volume.toLowerCase().contains('internacional')) {
            return ValidationResult(
              valid: false,
              reason: 'Solo se permiten mudanzas pequeñas dentro de la ciudad',
            );
          }
          break;

        case ServiceCategories.cleaning:
          // Verificar que no incluya sanitización clínica
          final cleaningType = serviceData?['cleaningType'] as String? ?? '';
          if (cleaningType.toLowerCase().contains('sanitización clínica') ||
              cleaningType.toLowerCase().contains('hospitalaria')) {
            return ValidationResult(
              valid: false,
              reason: 'La sanitización clínica requiere certificación especial y no está disponible',
            );
          }
          break;
      }

      return ValidationResult(valid: true);
    } catch (e) {
      AppLogger.e('Error validando restricciones de servicio', e);
      return ValidationResult(valid: true); // Por defecto permitir
    }
  }

  /// Verifica si un servicio técnico está regulado
  bool _isRegulatedTechService(String problem) {
    final regulatedKeywords = [
      'instalación eléctrica',
      'cableado estructurado',
      'cámaras de seguridad certificadas',
      'sistema de alarmas',
      'red eléctrica',
    ];

    final problemLower = problem.toLowerCase();
    return regulatedKeywords.any((keyword) => problemLower.contains(keyword));
  }

  /// Texto único para el diálogo de confirmación legal (sin repetir secciones).
  Future<String> buildConfirmationText({
    required String serviceId,
    required String serviceName,
  }) async {
    try {
      final service = await _serviceRepository.getServiceById(serviceId);
      final customNote = service?.legalDisclaimer?.trim();
      final categoryNote = service != null
          ? _categoryLegalNote(service.category)
          : null;

      final lines = <String>[
        'Al solicitar "$serviceName", declaras que comprendes y aceptas lo siguiente:',
        '',
        '• My Works App conecta usuarios con trabajadores independientes y actúa '
        'únicamente como intermediario tecnológico. No ejecuta el servicio, no emite '
        'certificaciones ni garantiza el resultado del trabajo.',
        '',
        '• El servicio será prestado por el profesional que seleccionaste, quien es '
        'responsable de la calidad, plazos, materiales y del cumplimiento de la '
        'normativa aplicable en su oficio.',
      ];

      if (customNote != null && customNote.isNotEmpty) {
        lines.addAll(['', '• $customNote']);
      } else if (categoryNote != null) {
        lines.addAll(['', '• $categoryNote']);
      }

      lines.addAll([
        '',
        '• Autorizas a la plataforma a coordinar la solicitud y gestionar el cobro '
        'conforme a los términos y políticas vigentes de My Works App.',
      ]);

      return lines.join('\n');
    } catch (e) {
      AppLogger.e('Error generando confirmación legal', e);
      return '${platformDisclaimer}\n\nAl continuar, aceptas los términos descritos.';
    }
  }

  static String formatClp(int amount) {
    return NumberFormat.currency(
      locale: 'es_CL',
      symbol: r'$',
      decimalDigits: 0,
    ).format(amount);
  }

  static String paymentNotice({int? chargeAmountClp}) {
    if (chargeAmountClp != null && chargeAmountClp > 0) {
      final formatted = formatClp(chargeAmountClp);
      return 'Al confirmar, se realizará un cobro de $formatted a la tarjeta de '
          'crédito o débito registrada en tu cuenta.';
    }
    return 'Al confirmar, autorizas el cobro del monto del servicio a la tarjeta '
        'de crédito o débito registrada en tu cuenta.';
  }

  String? _categoryLegalNote(String category) {
    switch (category) {
      case ServiceCategories.construction:
        return 'En trabajos de construcción o reparación, permisos municipales o '
            'exigencias técnicas —si corresponden— son responsabilidad del '
            'profesional y del cliente; la plataforma no supervisa la obra.';
      case ServiceCategories.plumbing:
        return 'Las intervenciones de fontanería son realizadas por técnicos '
            'independientes; daños preexistentes o instalaciones no conformes a '
            'norma pueden afectar el resultado del trabajo.';
      case ServiceCategories.electrical:
        return 'Trabajos eléctricos deben cumplir normativa SEC/RIC vigente; el '
            'profesional es responsable de la ejecución segura del servicio.';
      case ServiceCategories.moving:
        return 'Solo se contemplan mudanzas pequeñas dentro de la ciudad; objetos '
            'de alto valor o transporte comercial pueden requerir condiciones '
            'adicionales acordadas con el profesional.';
      default:
        return null;
    }
  }

  /// Obtiene el descargo de responsabilidad para un servicio
  Future<String> getServiceDisclaimer(String serviceId) async {
    try {
      final service = await _serviceRepository.getServiceById(serviceId);
      if (service?.legalDisclaimer != null &&
          service!.legalDisclaimer!.isNotEmpty) {
        return service.legalDisclaimer!;
      }
      return platformDisclaimer;
    } catch (e) {
      AppLogger.e('Error obteniendo descargo de responsabilidad', e);
      return platformDisclaimer;
    }
  }
}

/// Resultado de validación
class ValidationResult {
  final bool valid;
  final String? reason;
  final String? warning;

  ValidationResult({
    required this.valid,
    this.reason,
    this.warning,
  });
}

