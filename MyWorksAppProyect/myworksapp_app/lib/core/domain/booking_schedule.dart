import 'package:flutter/material.dart';

/// Límites del calendario de visita. [first] y [initial] son el mismo día
/// civil, así el selector no falla cuando `DateTime.now()` se llama dos veces.
class BookingSchedule {
  BookingSchedule._();

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static ({DateTime initial, DateTime first, DateTime last}) pickerBounds({
    DateTime? selected,
    DateTime? now,
    int horizonDays = 90,
  }) {
    final clock = now ?? DateTime.now();
    final first = dateOnly(clock);
    final last = first.add(Duration(days: horizonDays));
    var initial = selected == null ? first : dateOnly(selected);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    return (initial: initial, first: first, last: last);
  }
}

Future<DateTime?> pickBookingDate(
  BuildContext context, {
  DateTime? selected,
  int horizonDays = 90,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  final bounds = BookingSchedule.pickerBounds(
    selected: selected,
    horizonDays: horizonDays,
  );
  return showDatePicker(
    context: context,
    initialDate: bounds.initial,
    firstDate: bounds.first,
    lastDate: bounds.last,
  );
}
