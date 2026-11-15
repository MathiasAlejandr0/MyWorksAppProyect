import 'dart:typed_data';

/// Convierte bytea de PostgREST (hex `\x…`, lista o bytes) a [Uint8List].
Uint8List? decodeBytea(dynamic value) {
  if (value == null) return null;
  if (value is Uint8List) {
    return value.isEmpty ? null : value;
  }
  if (value is List) {
    if (value.isEmpty) return null;
    return Uint8List.fromList(value.map((item) => (item as num).toInt()).toList());
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final hex = trimmed.startsWith(r'\x') ? trimmed.substring(2) : trimmed;
    if (hex.length < 2 || hex.length.isOdd) return null;
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      final slice = hex.substring(i * 2, i * 2 + 2);
      final parsed = int.tryParse(slice, radix: 16);
      if (parsed == null) return null;
      bytes[i] = parsed;
    }
    return bytes;
  }
  return null;
}

/// Hex con prefijo `\x` que PostgREST acepta en columnas bytea.
String encodeByteaHex(Uint8List bytes) {
  final buffer = StringBuffer(r'\x');
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

bool isWebpBytes(Uint8List bytes) {
  if (bytes.length < 12) return false;
  return bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
}
