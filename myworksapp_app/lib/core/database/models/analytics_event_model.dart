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
      'eventName': eventName,
      'userId': userId,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'metadata': _encodeMetadata(metadata),
    };
  }

  factory AnalyticsEventModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsEventModel(
      id: map['id'] as String,
      eventName: map['eventName'] as String,
      userId: map['userId'] as String?,
      role: map['role'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: _decodeMetadata(map['metadata'] as String),
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

