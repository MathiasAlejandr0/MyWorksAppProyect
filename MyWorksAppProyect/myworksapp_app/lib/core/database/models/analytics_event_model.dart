import 'dart:convert';

/// Modelo para eventos de analytics
class AnalyticsEventModel {
  final String id;
  final String eventName;
  final String? userId;
  final String? role;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AnalyticsEventModel({
    required this.id,
    required this.eventName,
    this.userId,
    this.role,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_evento': eventName,
      'id_usuario': userId,
      'rol': role,
      'marca_tiempo': timestamp.toIso8601String(),
      'metadatos': _encodeMetadata(metadata),
    };
  }

  factory AnalyticsEventModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsEventModel(
      id: map['id'] as String,
      eventName: map['nombre_evento'] as String,
      userId: map['id_usuario'] as String?,
      role: map['rol'] as String?,
      timestamp: DateTime.parse(map['marca_tiempo'] as String),
      metadata: _decodeMetadata(map['metadatos'] as String),
    );
  }

  /// Codifica metadata a JSON string
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    try {
      return jsonEncode(metadata);
    } catch (e) {
      return '{}';
    }
  }

  /// Decodifica metadata de JSON string
  static Map<String, dynamic> _decodeMetadata(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}

