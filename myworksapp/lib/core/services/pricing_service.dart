import '../database/models/service_pricing_model.dart';
import '../domain/price_quote.dart';
import '../domain/pricing_constants.dart';
import '../domain/worker_service_options_catalog.dart';
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

  static const _comunaFactors = <String, double>{
    'providencia': 1.08,
    'las_condes': 1.10,
    'santiago': 1.0,
    'maipu': 0.95,
    'puente_alto': 0.92,
  };

  static const _skuBaseClp = <String, int>{
    'LOCK_CYLINDER_REPLACE': 45000,
    'WATER_HEATER_INSTALL': 120000,
    'FAUCET_REPLACE': 35000,
  };

  /// Precio fijo según tarifa publicada por el trabajador.
  PriceQuote calculateWorkerTierPrice({
    required String optionId,
    required String optionLabel,
    required int amountClp,
    String? comunaKey,
    WorkerPriceUnit unit = WorkerPriceUnit.fixed,
  }) {
    final factor = _comunaFactors[comunaKey?.toLowerCase()] ?? 1.0;
    final subtotal = (amountClp * factor).round();
    final fee = serviceFeeFor(subtotal);
    final unitLabel = unit == WorkerPriceUnit.perSqm ? 'por m²' : 'precio fijo';
    return PriceQuote(
      pricingMode: PricingConstants.modeFixedPrice,
      subtotalClp: subtotal,
      platformFeeClp: fee,
      totalClp: subtotal,
      workerPayoutClp: subtotal - fee,
      breakdown: {
        'worker_tier_id': optionId,
        'worker_tier_label': optionLabel,
        'base_clp': amountClp,
        'price_unit': unit.name,
        'comuna_factor': factor,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message:
          'Tarifa del profesional ($unitLabel). La comisión del servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.',
    );
  }

  /// Modalidad 1: precio fijo (SKU + comuna).
  Future<PriceQuote> calculateFixedPrice({
    required String skuCode,
    String? comunaKey,
    int comunaSurchargeClp = 0,
  }) async {
    final base = _skuBaseClp[skuCode] ?? 40000;
    final factor = _comunaFactors[comunaKey?.toLowerCase()] ?? 1.0;
    final subtotal = (base * factor).round() + comunaSurchargeClp;
    final fee = serviceFeeFor(subtotal);
    return PriceQuote(
      pricingMode: PricingConstants.modeFixedPrice,
      subtotalClp: subtotal,
      platformFeeClp: fee,
      totalClp: subtotal,
      workerPayoutClp: subtotal - fee,
      breakdown: {
        'sku_code': skuCode,
        'base_clp': base,
        'comuna_factor': factor,
        'comuna_surcharge_clp': comunaSurchargeClp,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message: 'Precio fijo de referencia del ítem. La comisión del servicio (5%, mínimo \$1.000) se descuenta del profesional.',
    );
  }

  /// Modalidad 2: bloque de horas × tarifa del trabajador.
  Future<PriceQuote> calculateHourlyBlock({
    required int hourlyRateClp,
    required int blockHours,
    String? comunaKey,
  }) async {
    if (![2, 4, 8].contains(blockHours)) {
      throw AppError.validation('El bloque debe ser de 2, 4 u 8 horas');
    }
    final factor = _comunaFactors[comunaKey?.toLowerCase()] ?? 1.0;
    final subtotal = (hourlyRateClp * blockHours * factor).round();
    final fee = serviceFeeFor(subtotal);
    return PriceQuote(
      pricingMode: PricingConstants.modeHourlyBlock,
      subtotalClp: subtotal,
      platformFeeClp: fee,
      totalClp: subtotal,
      workerPayoutClp: subtotal - fee,
      breakdown: {
        'hourly_rate_clp': hourlyRateClp,
        'block_hours': blockHours,
        'comuna_factor': factor,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message: 'Pago adelantado por bloque de $blockHours horas. La comisión del servicio (5%, mínimo \$1.000) se descuenta del profesional.',
    );
  }

  /// Tarifa de visita (agendar desde perfil del trabajador).
  PriceQuote calculateVisitBooking({
    required int visitFeeClp,
    String? comunaKey,
  }) {
    final factor = _comunaFactors[comunaKey?.toLowerCase()] ?? 1.0;
    final subtotal = (visitFeeClp * factor).round();
    const feePercent = 0.10;
    final fee = (subtotal * feePercent).round();
    return PriceQuote(
      pricingMode: PricingConstants.modeFixedPrice,
      subtotalClp: subtotal,
      platformFeeClp: fee,
      totalClp: subtotal + fee,
      breakdown: {
        'visit_fee_clp': visitFeeClp,
        'comuna_factor': factor,
      },
      message: 'Pago de visita con fondos en garantía hasta completar el servicio.',
    );
  }

  /// Horas extra fuera del bloque prepagado (modalidad hourly_block).
  PriceQuote calculateHourlyOvertime({
    required int hourlyRateClp,
    required int extraHours,
    String? comunaKey,
  }) {
    if (extraHours < 1 || extraHours > 8) {
      throw AppError.validation('Las horas extra deben ser entre 1 y 8');
    }
    final factor = _comunaFactors[comunaKey?.toLowerCase()] ?? 1.0;
    final subtotal = (hourlyRateClp * extraHours * factor * 1.15).round();
    final fee = serviceFeeFor(subtotal);
    return PriceQuote(
      pricingMode: PricingConstants.modeHourlyBlock,
      subtotalClp: subtotal,
      platformFeeClp: fee,
      totalClp: subtotal,
      workerPayoutClp: subtotal - fee,
      breakdown: {
        'overtime_hours': extraHours,
        'hourly_rate_clp': hourlyRateClp,
        'surge_factor': 1.15,
        'comuna_factor': factor,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message: 'Cobro por $extraHours hora(s) adicional(es). La comisión del servicio (5%, mínimo \$1.000) se descuenta del profesional.',
    );
  }

  /// Tarifa hora estimada desde tarifa de visita (demo, sin columna hourly en BD).
  int estimateHourlyRateFromVisitFee(int visitFeeClp) =>
      (visitFeeClp * 2.5).round().clamp(15000, 120000);

  /// Comisión del servicio: 5% del monto de la cotización aprobada,
  /// con un mínimo de [PricingService.minServiceFeeClp] CLP.
  static const double serviceFeeRate = 0.05;
  static const int minServiceFeeClp = 1000;

  int serviceFeeFor(int amountClp) {
    final fee = (amountClp * serviceFeeRate).round();
    return fee < minServiceFeeClp ? minServiceFeeClp : fee;
  }

  /// Modalidad 3: validar monto de propuesta aceptada.
  ///
  /// El cliente paga el total de la cotización aprobada. La comisión del
  /// servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.
  PriceQuote quoteFromOpenProposal({
    required int proposalAmountClp,
    int platformFeeClp = 0,
  }) {
    final fee = platformFeeClp > 0 ? platformFeeClp : serviceFeeFor(proposalAmountClp);
    final workerPayout = proposalAmountClp - fee;
    return PriceQuote(
      pricingMode: PricingConstants.modeOpenQuote,
      subtotalClp: proposalAmountClp,
      platformFeeClp: fee,
      totalClp: proposalAmountClp,
      workerPayoutClp: workerPayout,
      breakdown: {
        'proposal_amount_clp': proposalAmountClp,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': workerPayout,
      },
      message: 'La comisión del servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.',
    );
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

