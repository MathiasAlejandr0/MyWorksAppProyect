import 'package:flutter/material.dart';

/// Horarios de prueba ocupados. La validación es solo local:
/// no consulta trabajos ni hace llamadas a Supabase.
const List<String> mockReservedSlots = [
  '09:00',
  '11:00',
  '15:00',
  '18:00',
];

/// Bloques horarios que se ofrecen al agendar (incluye los ocupados).
const List<String> mockBookableSlots = [
  '08:00',
  '09:00',
  '10:00',
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
  '18:00',
  '19:00',
  '20:00',
];

class MockReservedSlots {
  MockReservedSlots._();

  static const String reservedMessage =
      'Esta hora ya se encuentra reservada. Por favor elige otro horario.';

  static bool isReservedLabel(String label) => mockReservedSlots.contains(label);

  static String format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static bool isReserved(TimeOfDay time) => isReservedLabel(format(time));

  static TimeOfDay parse(String label) {
    final parts = label.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}
