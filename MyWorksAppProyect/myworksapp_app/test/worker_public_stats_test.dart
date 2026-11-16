import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/database/job_amount_hydrator.dart';
import 'package:myworksapp/core/database/models/payment_model.dart';
import 'package:myworksapp/core/domain/worker_public_stats.dart';

void main() {
  group('WorkerPublicStats', () {
    test('la etiqueta usa una decimal y Nuevo si no hay reseñas', () {
      expect(WorkerPublicStats.ratingLabel(4.88), '4.9');
      expect(WorkerPublicStats.ratingLabel(5.0), '5.0');
      expect(WorkerPublicStats.ratingLabel(0), 'Nuevo');
      expect(WorkerPublicStats.ratingLabel(null), 'Nuevo');
      expect(WorkerPublicStats.ratingLabel(4.9, ratingCount: 0), 'Nuevo');
    });

    test('fromMap no inventa una nota cuando no hay reseñas', () {
      final stats = WorkerPublicStats.fromMap({
        'calificacion': 4.9,
        'n_calificaciones': 0,
        'trabajos_completados': 8,
        'es_elite': true,
      });
      expect(stats.averageRating, isNull);
      expect(
        WorkerPublicStats.ratingLabel(
          stats.averageRating,
          ratingCount: stats.ratingCount,
        ),
        'Nuevo',
      );
      expect(stats.completedJobs, 8);
    });

    test('fromMap usa el promedio real cuando hay reseñas', () {
      final stats = WorkerPublicStats.fromMap({
        'calificacion': 4.80,
        'n_calificaciones': 5,
        'trabajos_completados': 5,
        'es_elite': true,
      });
      expect(stats.averageRating, 4.80);
      expect(WorkerPublicStats.ratingLabel(stats.averageRating), '4.8');
      expect(stats.isElite, isTrue);
    });
  });

  group('knownAmountFromPayments', () {
    PaymentModel pay({
      required double amount,
      required String status,
      String type = 'principal',
      String? changeOrderId,
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return PaymentModel(
        id: 'p-$amount-$status',
        jobId: 'job-1',
        amount: amount,
        status: status,
        paymentType: type,
        changeOrderId: changeOrderId,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('prefiere el pago principal liberado sobre una orden de cambio', () {
      expect(
        knownAmountFromPayments([
          pay(
            amount: 5000,
            status: 'liberado',
            type: 'orden_cambio',
            changeOrderId: 'co-1',
          ),
          pay(amount: 28000, status: 'retenido'),
        ]),
        28000,
      );
    });

    test('ignora reembolsos y montos vacíos', () {
      expect(
        knownAmountFromPayments([
          pay(amount: 0, status: 'liberado'),
          pay(amount: 25000, status: 'reembolsado'),
        ]),
        isNull,
      );
    });
  });
}
