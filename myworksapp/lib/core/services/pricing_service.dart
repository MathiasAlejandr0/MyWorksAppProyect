import '../database/repositories/service_repository.dart';
import '../database/models/service_pricing_model.dart';
import '../utils/app_logger.dart';
import '../utils/app_error.dart';

/// Resultado de cálculo de precio
class PriceEstimate {
  final double estimatedPrice;
  final double minimumPrice;
  final double hourlyRate;
  final String currency;
  final String? message; // Mensaje explicativo

  PriceEstimate({
    required this.estimatedPrice,
    required this.minimumPrice,
    required this.hourlyRate,
    this.currency = 'USD',
    this.message,
  });

  /// Formatea el precio para mostrar
  String getFormattedPrice() {
    return '${currency == 'USD' ? '\$' : currency} ${estimatedPrice.toStringAsFixed(2)}';
  }

  /// Formatea el precio mínimo
  String getFormattedMinimum() {
    return '${currency == 'USD' ? '\$' : currency} ${minimumPrice.toStringAsFixed(2)}';
  }
}

/// Servicio para cálculo de precios
/// 
/// Calcula precios estimados basados en:
/// - Precio base del servicio
/// - Tarifa mínima
/// - Precio por hora
/// - Duración estimada (opcional)
/// 
/// Preparado para override server-side en el futuro.
class PricingService {
  static final PricingService instance = PricingService._();
  PricingService._();

  final ServiceRepository _serviceRepository = ServiceRepository();

  // Cache local de precios (por serviceId)
  final Map<String, ServicePricingModel> _pricingCache = {};

  /// Obtiene el precio estimado para un servicio
  /// 
  /// [estimatedHours] es opcional. Si no se proporciona, retorna precio base.
  Future<PriceEstimate> getPriceEstimate({
    required String serviceId,
    double? estimatedHours,
  }) async {
    try {
      // 1. Obtener pricing del servicio
      final pricing = await _getServicePricing(serviceId);
      if (pricing == null) {
        // Precio por defecto si no existe
        return PriceEstimate(
          estimatedPrice: 50.0,
          minimumPrice: 30.0,
          hourlyRate: 25.0,
          currency: 'USD',
          message: 'Precio estimado. El precio final puede variar según el trabajo.',
        );
      }

      // 2. Calcular precio estimado
      double estimatedPrice = pricing.basePrice;

      if (estimatedHours != null && estimatedHours > 0) {
        // Precio = base + (horas * tarifa por hora)
        estimatedPrice = pricing.basePrice + (estimatedHours * pricing.hourlyRate);
      }

      // 3. Aplicar tarifa mínima
      if (estimatedPrice < pricing.minimumFee) {
        estimatedPrice = pricing.minimumFee;
      }

      // 4. Generar mensaje
      final message = estimatedHours != null
          ? 'Precio estimado para ${estimatedHours.toStringAsFixed(1)} horas. El precio final puede variar según la complejidad del trabajo.'
          : 'Precio base estimado. El precio final puede variar según la duración y complejidad del trabajo.';

      return PriceEstimate(
        estimatedPrice: estimatedPrice,
        minimumPrice: pricing.minimumFee,
        hourlyRate: pricing.hourlyRate,
        currency: pricing.currency ?? 'USD',
        message: message,
      );
    } catch (e) {
      AppLogger.e('Error calculando precio estimado', e);
      // Retornar precio por defecto en caso de error
      return PriceEstimate(
        estimatedPrice: 50.0,
        minimumPrice: 30.0,
        hourlyRate: 25.0,
        currency: 'USD',
        message: 'Precio estimado. El precio final puede variar.',
      );
    }
  }

  /// Obtiene el pricing de un servicio (con cache)
  Future<ServicePricingModel?> _getServicePricing(String serviceId) async {
    // Verificar cache
    if (_pricingCache.containsKey(serviceId)) {
      return _pricingCache[serviceId];
    }

    try {
      // Obtener desde base de datos
      // Nota: Por ahora, retornamos null y usamos precios por defecto
      // En producción, esto vendría de la tabla service_pricing
      
      // TODO: Implementar cuando tengamos la tabla service_pricing
      // final pricing = await _serviceRepository.getServicePricing(serviceId);
      // if (pricing != null) {
      //   _pricingCache[serviceId] = pricing;
      //   return pricing;
      // }

      return null;
    } catch (e) {
      AppLogger.e('Error obteniendo pricing del servicio', e);
      return null;
    }
  }

  /// Limpia el cache de precios
  void clearCache() {
    _pricingCache.clear();
  }

  /// Actualiza el pricing de un servicio (para override server-side)
  Future<void> updatePricing(ServicePricingModel pricing) async {
    try {
      _pricingCache[pricing.serviceId] = pricing;
      // TODO: Guardar en base de datos cuando tengamos la tabla
      AppLogger.i('Pricing actualizado para servicio: ${pricing.serviceId}');
    } catch (e) {
      AppLogger.e('Error actualizando pricing', e);
    }
  }
}

