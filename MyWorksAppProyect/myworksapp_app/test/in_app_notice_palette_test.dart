import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/notification_listener_scope.dart';

double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance()
      ? a.computeLuminance()
      : b.computeLuminance();
  final darker = a.computeLuminance() > b.computeLuminance()
      ? b.computeLuminance()
      : a.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const darkCanvas = Color(0xFF0B1424);
  const lightCanvas = Color(0xFFF7F5F2);

  test('en tema oscuro el cartel es claro y el texto oscuro', () {
    final palette = inAppNoticePalette(Brightness.dark);
    expect(_contrast(palette.background, darkCanvas), greaterThanOrEqualTo(4.5));
    expect(_contrast(palette.title, palette.background), greaterThanOrEqualTo(7));
    expect(_contrast(palette.body, palette.background), greaterThanOrEqualTo(4.5));
    expect(_contrast(palette.icon, palette.background), greaterThanOrEqualTo(3));
  });

  test('en tema claro el cartel es oscuro y el texto claro', () {
    final palette = inAppNoticePalette(Brightness.light);
    expect(_contrast(palette.background, lightCanvas), greaterThanOrEqualTo(4.5));
    expect(_contrast(palette.title, palette.background), greaterThanOrEqualTo(7));
    expect(_contrast(palette.body, palette.background), greaterThanOrEqualTo(4.5));
    expect(_contrast(palette.icon, palette.background), greaterThanOrEqualTo(3));
  });
}
