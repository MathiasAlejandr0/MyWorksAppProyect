import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/domain/generated_domain.dart';

void main() {
  group('Generated domain ES', () {
    test('GeneratedUserRoles usa códigos BD en español', () {
      expect(GeneratedUserRoles.user, 'usuario');
      expect(GeneratedUserRoles.worker, 'trabajador');
      expect(GeneratedUserRoles.admin, 'administrador');
    });

    test('GeneratedJobStatuses usa códigos BD en español', () {
      expect(GeneratedJobStatuses.pending, 'pendiente');
      expect(GeneratedJobStatuses.inProgress, 'en_curso');
      expect(GeneratedJobStatuses.awaitingPayment, 'esperando_pago');
      expect(
        GeneratedJobStatuses.awaitingClientApproval,
        'esperando_aprobacion_cliente',
      );
    });

    test('GeneratedPaymentStatuses y PricingModes ES', () {
      expect(GeneratedPaymentStatuses.held, 'retenido');
      expect(GeneratedPricingModes.fixedPrice, 'precio_fijo');
    });

    test('GeneratedDisputeStatuses ES', () {
      expect(GeneratedDisputeStatuses.open, 'abierta');
      expect(GeneratedDisputeStatuses.underReview, 'en_revision');
      expect(GeneratedDisputeStatuses.resolved, 'resuelta');
    });

    test('GeneratedWorkerActiveJobStatuses ES', () {
      expect(
        GeneratedWorkerActiveJobStatuses.values,
        containsAll([
          'aceptado',
          'en_curso',
          'esperando_aprobacion_cliente',
          'esperando_pago',
          'pausado_orden_cambio',
          'cotizacion_seleccionada',
        ]),
      );
    });
  });
}
