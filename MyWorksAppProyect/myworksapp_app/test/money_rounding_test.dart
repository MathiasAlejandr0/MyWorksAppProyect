import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/models/worker_model.dart';
import 'package:myworksapp/core/domain/clp_rounding.dart';
import 'package:myworksapp/core/domain/distance_match.dart';
import 'package:myworksapp/core/domain/transport_surcharge.dart';
import 'package:myworksapp/core/domain/worker_highlight.dart';
import 'package:myworksapp/core/services/change_order_service.dart';
import 'package:myworksapp/core/services/pricing_service.dart';
import 'package:myworksapp/core/database/models/change_order_model.dart';

void main() {
  test('el ,5 sube y el m² redondea la unidad antes de multiplicar', () {
    expect(roundClp(1500.5), 1501);
    expect(roundClp(1500.4), 1500);
    expect(roundClp(1500.6), 1501);
    expect(publishedServiceClp(rate: 1500.6, squareMeters: 40), 60040);
    expect(roundHalfAway(7 * 8, 100), 1);
    expect(roundHalfAway(6 * 8, 100), 0);
    expect(changeOrderFeeClp(12), 1);
    expect(changeOrderTotalClp(1000), 1080);
  });

  test('horas extra no usan el 1,08 binario', () {
    final exact = overtimeAmountClp(
      hourlyRateClp: 19250,
      extraHours: 1,
      comunaKey: 'providencia',
    );
    expect(exact, 23909);
    expect((19250 * 1.08 * 1.15).round(), isNot(exact));
    final quote = PricingService.instance.calculateHourlyOvertime(
      hourlyRateClp: 19250,
      extraHours: 1,
      comunaKey: 'providencia',
    );
    expect(quote.subtotalClp, exact);
  });

  test('el bloque de horas no aplica factor de comuna', () async {
    final quote = await PricingService.instance.calculateHourlyBlock(
      hourlyRateClp: 20000,
      blockHours: 4,
      comunaKey: 'las_condes',
    );
    expect(quote.totalClp, 80000);
    expect(
      PricingService.instance.estimateHourlyRateFromVisitFee(10001),
      25003,
    );
  });

  test('la orden de cambio cobra el 8 % entero', () {
    final order = ChangeOrderModel(
      id: 'co',
      jobId: 'job',
      workerId: 'worker',
      tipo: 'extra_work',
      titulo: 'Extra',
      descripcion: 'Detalle',
      montoClp: 19250,
      estado: 'pendiente_cliente',
      createdAt: DateTime.utc(2026, 11, 20),
    );
    final quote = ChangeOrderService.instance.buildQuote(order);
    expect(quote.platformFeeClp, changeOrderFeeClp(19250));
    expect(quote.totalClp, 19250 + changeOrderFeeClp(19250));
  });

  test('la tarifa publicada no se trunca', () {
    final worker = WorkerModel.fromMap({
      'id_usuario': 'w',
      'profesion': 'Gasfíter',
      'tarifa_visita': 65000.6,
      'trabajador_precios': [
        {'codigo': 'construction_per_sqm', 'monto_clp': 1500.6},
      ],
    });
    expect(roundClp(worker.visitFee), 65001);
    expect(worker.pricingTiers['construction_per_sqm'], 1501);
  });

  test('el catálogo no dice dentro ni cobra con la base redondeada', () {
    final worker = WorkerModel.fromCatalogMap({
      'id_usuario': 'w',
      'profesion': 'Gasfíter',
      'latitud_base': -41.47,
      'longitud_base': -72.94,
      'radio_servicio_km': 6.6,
    });
    expect(worker.catalogBaseIsApproximate, isTrue);
    final notice = coverageNotice(
      worker: worker,
      clientLatitude: -41.469,
      clientLongitude: -72.941,
    );
    expect(notice.inside, isNull);
    expect(notice.text, contains('6,6 km'));
    expect(notice.text, isNot(contains('Dentro')));
    final quote = transportSurcharge(
      workerLat: worker.baseLatitude,
      workerLng: worker.baseLongitude,
      jobLat: -41.40,
      jobLng: -72.80,
      radiusKm: worker.serviceRadiusKm,
      catalogBaseIsApproximate: true,
    );
    expect(quote.extraClp, 0);
    expect(quote.insideRadar, isNull);
  });

  test('asin y atan2, ya cuantizados, cobran el mismo traslado', () {
    const workerLat = -41.4718;
    const workerLng = -72.9396;
    const jobLat = -41.4499;
    const jobLng = -72.8148;
    final charged = transportSurcharge(
      workerLat: workerLat,
      workerLng: workerLng,
      jobLat: jobLat,
      jobLng: jobLng,
      radiusKm: 7,
    );
    final atanKm = quantizeChargeKm(
      haversineKm(workerLat, workerLng, jobLat, jobLng),
    );
    final extraKm = (atanKm - 7).clamp(0.0, double.infinity);
    final raw = (extraKm * 1200).round().clamp(3000, 18000);
    expect(charged.extraClp, raw);
    expect(charged.distanceKm, quantizeChargeKm(haversineKmForCharge(
      workerLat,
      workerLng,
      jobLat,
      jobLng,
    )));
  });

  test('el texto del radio no redondea 6,6 a 7', () {
    expect(formatServiceRadiusKm(6.6), '6,6');
    expect(formatServiceRadiusKm(6.54), '6,5');
    expect(formatServiceRadiusKm(7), '7');
    expect(withinTravelRange(30.0004), isTrue);
    expect(withinTravelRange(30.0006), isFalse);
  });

  test('la visita no suma la tarifa fuera de radio guardada', () {
    final quote = PricingService.instance.calculateVisitBooking(
      visitFeeClp: 65000,
      transportExtraClp: 0,
    );
    expect(quote.totalClp, 65000);
  });
}
