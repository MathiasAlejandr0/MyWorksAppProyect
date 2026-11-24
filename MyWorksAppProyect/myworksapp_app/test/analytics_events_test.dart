import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/services/analytics_service.dart';

void main() {
  test('los eventos de uso usan los mismos nombres que la web', () {
    expect(AnalyticsEvents.vioFichaProfesional, 'vio_ficha_profesional');
    expect(AnalyticsEvents.eligioHoraReserva, 'eligio_hora_reserva');
    expect(AnalyticsEvents.confirmoPedido, 'confirmo_pedido');
  });
}
