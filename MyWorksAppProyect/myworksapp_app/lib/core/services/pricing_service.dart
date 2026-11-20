import '../domain/clp_rounding.dart';
import '../domain/job_charge_preview.dart';
import '../domain/price_quote.dart';
import '../domain/pricing_constants.dart';
import '../domain/worker_service_options_catalog.dart';
import '../utils/app_error.dart';

/// Servicio para cálculo de precios
///
/// Cotizaciones en CLP (visita, bloque por hora, tarifas del profesional y
/// propuestas abiertas). El monto que se cobra lo valida el servidor
/// (`monto_esperado_trabajo`).
class PricingService {
  static final PricingService instance = PricingService._();
  PricingService._();

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
    int? squareMeters,
    int? unitRateClp,
    int transportExtraClp = 0,
  }) {
    final rate = publishedServiceClp(rate: unitRateClp ?? amountClp);
    final baseTotal = unit == WorkerPriceUnit.perSqm && (squareMeters ?? 0) > 0
        ? rate * squareMeters!
        : amountClp;
    final extra = transportExtraClp < 0 ? 0 : transportExtraClp;
    // El servidor cobra la tarifa publicada más traslado si el trabajo queda fuera del radar.
    final subtotal = baseTotal + extra;
    final fee = serviceFeeFor(subtotal);
    final unitLabel = unit == WorkerPriceUnit.perSqm ? 'por m²' : 'precio fijo';
    final m2 = squareMeters ?? 0;
    final transferNote = extra > 0
        ? ' Incluye ${_formatClp(extra)} de traslado porque el trabajo queda fuera del área cercana.'
        : ' Sin extra de traslado: el trabajo queda dentro del radar.';
    final message = unit == WorkerPriceUnit.perSqm && m2 > 0
        ? 'Proyecto de $m2 m² × ${_formatClp(rate)}/m².$transferNote La comisión del servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.'
        : 'Tarifa del profesional ($unitLabel).$transferNote La comisión del servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.';
    return PriceQuote(
      pricingMode: PricingConstants.modeFixedPrice,
      subtotalClp: subtotal,
      platformFeeClp: fee,
      totalClp: subtotal,
      workerPayoutClp: subtotal - fee,
      breakdown: {
        'worker_tier_id': optionId,
        'worker_tier_label': optionLabel,
        'base_clp': baseTotal,
        'unit_rate_clp': rate,
        if (m2 > 0) 'square_meters': m2,
        'price_unit': unit.name,
        'transport_extra_clp': extra,
        if (comunaKey != null) 'comuna_key': comunaKey,
        'comuna_factor': 1,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message: message,
    );
  }

  static String _formatClp(int value) {
    final s = value.toString();
    if (s.length <= 3) return '\$$s';
    final buf = StringBuffer('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Modalidad 1: precio fijo (SKU + comuna).
  Future<PriceQuote> calculateFixedPrice({
    required String skuCode,
    String? comunaKey,
    int comunaSurchargeClp = 0,
  }) async {
    final base = _skuBaseClp[skuCode] ?? 40000;
    final subtotal = applyComunaFactor(base, comunaKey) + comunaSurchargeClp;
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
        'comuna_factor': (comunaFactorHundredths[comunaKey?.toLowerCase()] ?? 100) / 100,
        'comuna_surcharge_clp': comunaSurchargeClp,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message:
          'Precio fijo de referencia del ítem. La comisión del servicio (5%, mínimo \$1.000) se descuenta del profesional.',
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
    // El servidor cobra visita×2,5×horas, sin factor de comuna, y le suma el traslado real.
    final subtotal = hourlyRateClp * blockHours;
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
        if (comunaKey != null) 'comuna_key': comunaKey,
        'comuna_factor': 1,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message:
          'Pago adelantado por bloque de $blockHours horas. La comisión del servicio (5%, mínimo \$1.000) se descuenta del profesional.',
    );
  }

  /// Tarifa de visita (agendar desde perfil del trabajador).
  PriceQuote calculateVisitBooking({
    required int visitFeeClp,
    String? comunaKey,
    int transportExtraClp = 0,
  }) {
    final extra = transportExtraClp < 0 ? 0 : transportExtraClp;
    // El servidor cobra `tarifa_visita + recargo_traslado`, sin comisión extra
    // al cliente. Si el total no coincide, Webpay no abre.
    final subtotal = visitFeeClp + extra;
    final fee = serviceFeeFor(subtotal);
    return PriceQuote(
      pricingMode: PricingConstants.modeFixedPrice,
      subtotalClp: subtotal,
      platformFeeClp: fee,
      totalClp: subtotal,
      workerPayoutClp: subtotal - fee,
      breakdown: {
        'visit_fee_clp': visitFeeClp,
        'transport_extra_clp': extra,
        if (comunaKey != null) 'comuna_key': comunaKey,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message: extra > 0
          ? 'Pago de visita más ${_formatClp(extra)} de traslado (fuera del área cercana). La comisión se descuenta del profesional.'
          : 'Pago de visita con fondos en garantía. Sin extra de traslado. La comisión se descuenta del profesional.',
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
    final subtotal = overtimeAmountClp(
      hourlyRateClp: hourlyRateClp,
      extraHours: extraHours,
      comunaKey: comunaKey,
    );
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
        'comuna_factor': (comunaFactorHundredths[comunaKey?.toLowerCase()] ?? 100) / 100,
        'service_fee_rate': serviceFeeRate,
        'service_fee_clp': fee,
        'worker_payout_clp': subtotal - fee,
      },
      message:
          'Cobro por $extraHours hora(s) adicional(es). La comisión del servicio (5%, mínimo \$1.000) se descuenta del profesional.',
    );
  }

  /// Tarifa hora estimada desde tarifa de visita (demo, sin columna hourly en BD).
  int estimateHourlyRateFromVisitFee(int visitFeeClp) =>
      hourlyRateFromVisitFee(visitFeeClp);

  /// Comisión del servicio: 5% del monto de la cotización aprobada,
  /// con un mínimo de [PricingService.minServiceFeeClp] CLP.
  ///
  /// Misma regla que `comision_servicio_clp`: redondeo half-away,
  /// mínimo $1.000 y nunca mayor que el bruto.
  static const double serviceFeeRate = 0.05;
  static const int minServiceFeeClp = 1000;

  int serviceFeeFor(int amountClp) {
    if (amountClp <= 0) return 0;
    final percent = roundHalfAway(amountClp * 5, 100);
    final withMinimum = percent < minServiceFeeClp ? minServiceFeeClp : percent;
    return withMinimum > amountClp ? amountClp : withMinimum;
  }

  /// Líneas que se muestran juntas en el cobro.
  /// Tarifa + traslado = total, y comisión + neto = total.
  ({int? serviceClp, int transportClp, int totalClp, int feeClp, int payoutClp})
      workerChargeLines(PriceQuote quote) {
    final total = quote.totalClp < 0 ? 0 : quote.totalClp;
    final fee = serviceFeeFor(total);
    final payout = total - fee;
    final published = _breakdownClp(quote.breakdown, 'base_clp') ??
        _breakdownClp(quote.breakdown, 'visit_fee_clp');
    if (published == null) {
      return (
        serviceClp: null,
        transportClp: 0,
        totalClp: total,
        feeClp: fee,
        payoutClp: payout,
      );
    }
    final serviceClp = published.clamp(0, total);
    return (
      serviceClp: serviceClp,
      transportClp: total - serviceClp,
      totalClp: total,
      feeClp: fee,
      payoutClp: payout,
    );
  }

  /// El resumen se arma con este desglose antes de confirmar. Tarifa y
  /// traslado salen de la ubicación real (la misma que cobra el servidor),
  /// en pesos enteros, y la comisión se recalcula sobre ese total.
  PriceQuote applyServerCharge(PriceQuote quote, JobChargePreview preview) {
    final total = preview.totalClp < 0 ? 0 : preview.totalClp;
    final service = preview.serviceClp.clamp(0, total);
    final transport = total - service;
    final fee = preview.feeClp.clamp(0, total);
    final payout = total - fee;
    final breakdown = Map<String, dynamic>.from(quote.breakdown);
    breakdown['base_clp'] = service;
    breakdown['visit_fee_clp'] = service;
    breakdown['transport_extra_clp'] = transport;
    breakdown['service_fee_clp'] = fee;
    breakdown['worker_payout_clp'] = payout;
    return PriceQuote(
      pricingMode: quote.pricingMode,
      subtotalClp: total,
      platformFeeClp: fee,
      totalClp: total,
      workerPayoutClp: payout,
      currency: quote.currency,
      breakdown: breakdown,
      message:
          'Tarifa y traslado calculados con la ubicación real del profesional. La comisión del servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.',
    );
  }

  /// El mapa muestra la base redondeada (~1 km). El cobro usa la coordenada
  /// real, así que el total de la pantalla a veces no es el que acepta el
  /// servidor. Esta copia deja el desglose alineado con ese monto: la
  /// diferencia queda en el traslado para que tarifa + traslado = total.
  PriceQuote alignToChargedTotal(PriceQuote quote, int totalClp) {
    final total = totalClp < 0 ? 0 : totalClp;
    final fee = serviceFeeFor(total);
    final deducts = quote.feeDeductedFromWorker;
    final breakdown = Map<String, dynamic>.from(quote.breakdown);
    final published = _breakdownClp(breakdown, 'base_clp') ??
        _breakdownClp(breakdown, 'visit_fee_clp');
    if (published != null && breakdown.containsKey('transport_extra_clp')) {
      final serviceClp = published.clamp(0, total);
      breakdown['transport_extra_clp'] = total - serviceClp;
      if (breakdown.containsKey('base_clp')) breakdown['base_clp'] = serviceClp;
      if (breakdown.containsKey('visit_fee_clp')) {
        breakdown['visit_fee_clp'] = serviceClp;
      }
    }
    breakdown['adjusted_from_clp'] = quote.totalClp;
    breakdown['service_fee_clp'] = fee;
    if (deducts) breakdown['worker_payout_clp'] = total - fee;
    return PriceQuote(
      pricingMode: quote.pricingMode,
      subtotalClp: total,
      platformFeeClp: fee,
      totalClp: total,
      workerPayoutClp: deducts ? total - fee : quote.workerPayoutClp,
      currency: quote.currency,
      breakdown: breakdown,
      message:
          'El traslado usa la ubicación real del profesional. La comisión del servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.',
    );
  }

  /// Modalidad 3: validar monto de propuesta aceptada.
  ///
  /// El cliente paga el total de la cotización aprobada. La comisión del
  /// servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.
  PriceQuote quoteFromOpenProposal({
    required int proposalAmountClp,
    int platformFeeClp = 0,
  }) {
    final fee =
        platformFeeClp > 0 ? platformFeeClp : serviceFeeFor(proposalAmountClp);
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
      message:
          'La comisión del servicio (5%, mínimo \$1.000) se descuenta del pago al profesional.',
    );
  }
}

int? _breakdownClp(Map<String, dynamic> breakdown, String key) {
  final value = breakdown[key];
  if (value is num) return value.round();
  return null;
}
