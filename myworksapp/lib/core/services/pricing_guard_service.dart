import '../database/repositories/job_repository.dart';
import '../database/repositories/service_repository.dart';
import '../utils/app_logger.dart';

/// Servicio de protección de precios
/// 
/// Funciones:
/// - Calcular rango recomendado por servicio
/// - Detectar precios extremos
/// - Mostrar alertas NO bloqueantes (solo educar)
class PricingGuardService {
  static final PricingGuardService instance = PricingGuardService._();
  PricingGuardService._();

  final JobRepository _jobRepository = JobRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();

  /// Rango de precios recomendado por servicio (en CLP)
  /// Estos valores son estimaciones y pueden ajustarse según datos reales
  static const Map<String, PriceRange> defaultPriceRanges = {
    'limpieza': PriceRange(min: 15000, max: 50000, average: 25000),
    'plomeria': PriceRange(min: 25000, max: 80000, average: 45000),
    'electricidad': PriceRange(min: 30000, max: 100000, average: 60000),
    'construccion': PriceRange(min: 50000, max: 200000, average: 100000),
    'jardineria': PriceRange(min: 20000, max: 60000, average: 35000),
    'montaje': PriceRange(min: 20000, max: 70000, average: 40000),
    'mudanza': PriceRange(min: 40000, max: 150000, average: 80000),
    'support_it': PriceRange(min: 20000, max: 60000, average: 35000),
  };

  /// Verifica si un precio es extremo y retorna una alerta si es necesario
  /// 
  /// Retorna null si el precio está dentro del rango normal
  Future<PricingAlert?> checkPrice({
    required String serviceId,
    required double price,
  }) async {
    try {
      // Obtener rango recomendado para el servicio
      final priceRange = await _getPriceRangeForService(serviceId);
      
      // Calcular desviación del promedio
      final deviation = ((price - priceRange.average) / priceRange.average * 100).abs();
      
      // Detectar precios extremos
      if (price < priceRange.min * 0.5) {
        return PricingAlert(
          type: PricingAlertType.tooLow,
          message: 'Este precio es significativamente más bajo que el promedio '
              '(${_formatPrice(priceRange.average)}). Asegúrate de que el trabajador '
              'pueda completar el trabajo con este presupuesto.',
          severity: PricingAlertSeverity.warning,
        );
      } else if (price > priceRange.max * 1.5) {
        return PricingAlert(
          type: PricingAlertType.tooHigh,
          message: 'Este precio es significativamente más alto que el promedio '
              '(${_formatPrice(priceRange.average)}). Considera comparar con otros '
              'trabajadores antes de confirmar.',
          severity: PricingAlertSeverity.info,
        );
      } else if (deviation > 50) {
        // Precio fuera del rango normal pero no extremo
        if (price > priceRange.average) {
          return PricingAlert(
            type: PricingAlertType.high,
            message: 'Este precio está por encima del promedio del mercado. '
                'Asegúrate de que el valor ofrecido justifique la diferencia.',
            severity: PricingAlertSeverity.info,
          );
        } else {
          return PricingAlert(
            type: PricingAlertType.low,
            message: 'Este precio está por debajo del promedio del mercado. '
                'Verifica que el alcance del trabajo esté claro.',
            severity: PricingAlertSeverity.info,
          );
        }
      }
      
      // Precio dentro del rango normal
      return null;
    } catch (e) {
      AppLogger.e('Error al verificar precio', e);
      return null; // No bloquear por errores
    }
  }

  /// Obtiene el rango de precios recomendado para un servicio
  Future<PriceRange> _getPriceRangeForService(String serviceId) async {
    try {
      // Intentar obtener datos históricos de trabajos completados
      final allJobs = await _jobRepository.getJobsByStatus('completed');
      final completedJobs = allJobs.where((j) => j.serviceId == serviceId).toList();
      
      if (completedJobs.length >= 5) {
        // Calcular estadísticas basadas en datos reales
        final prices = completedJobs
            .map((j) => _extractPriceFromJob(j))
            .where((p) => p != null)
            .map((p) => p!)
            .toList();
        
        if (prices.isNotEmpty) {
          prices.sort();
          final min = prices.first;
          final max = prices.last;
          final average = prices.reduce((a, b) => a + b) / prices.length;
          
          return PriceRange(
            min: (min * 0.8).roundToDouble(), // 20% de margen inferior
            max: (max * 1.2).roundToDouble(), // 20% de margen superior
            average: average.roundToDouble(),
          );
        }
      }
      
      // Si no hay suficientes datos, usar rango por defecto
      final service = await _serviceRepository.getServiceById(serviceId);
      final serviceName = service?.name.toLowerCase() ?? serviceId.toLowerCase();
      
      // Buscar rango por nombre o categoría
      for (final entry in defaultPriceRanges.entries) {
        if (serviceName.contains(entry.key) || 
            service?.category.toLowerCase().contains(entry.key) == true) {
          return entry.value;
        }
      }
      
      // Rango genérico por defecto
      return const PriceRange(min: 20000, max: 100000, average: 50000);
    } catch (e) {
      AppLogger.e('Error al obtener rango de precios', e);
      // Rango genérico por defecto en caso de error
      return const PriceRange(min: 20000, max: 100000, average: 50000);
    }
  }

  /// Extrae el precio de un trabajo (desde serviceMetadata o estimación)
  double? _extractPriceFromJob(dynamic job) {
    // TODO: Implementar extracción real del precio desde job.serviceMetadata
    // Por ahora, retornar null para usar rangos por defecto
    return null;
  }

  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} CLP';
  }
}

/// Rango de precios recomendado
class PriceRange {
  final double min;
  final double max;
  final double average;

  const PriceRange({
    required this.min,
    required this.max,
    required this.average,
  });
}

/// Alerta de precio
class PricingAlert {
  final PricingAlertType type;
  final String message;
  final PricingAlertSeverity severity;

  PricingAlert({
    required this.type,
    required this.message,
    required this.severity,
  });
}

enum PricingAlertType {
  tooLow,
  tooHigh,
  low,
  high,
}

enum PricingAlertSeverity {
  info,
  warning,
}

