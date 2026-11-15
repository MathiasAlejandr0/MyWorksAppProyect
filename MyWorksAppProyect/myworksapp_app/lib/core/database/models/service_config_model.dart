import 'dart:convert';

/// Modelo para configuraciones específicas de servicios
/// 
/// Almacena el schema JSON de campos personalizados por servicio.
class ServiceConfigModel {
  final String id;
  final String serviceId;
  final Map<String, dynamic> configSchema; // Schema JSON de campos
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceConfigModel({
    required this.id,
    required this.serviceId,
    required this.configSchema,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_servicio': serviceId,
      'esquema_config': _encodeSchema(configSchema),
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory ServiceConfigModel.fromMap(Map<String, dynamic> map) {
    return ServiceConfigModel(
      id: map['id'] as String,
      serviceId: map['id_servicio'] as String,
      configSchema: _decodeSchema(map['esquema_config'] as String?),
      createdAt: DateTime.parse(map['creado_en'] as String),
      updatedAt: DateTime.parse(map['actualizado_en'] as String),
    );
  }

  /// Codifica schema a JSON string
  static String _encodeSchema(Map<String, dynamic> schema) {
    try {
      return jsonEncode(schema);
    } catch (e) {
      return '{}';
    }
  }

  /// Decodifica schema de JSON string
  static Map<String, dynamic> _decodeSchema(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Obtiene campos requeridos del schema
  List<String> getRequiredFields() {
    final fields = <String>[];
    if (configSchema.containsKey('fields')) {
      final fieldsList = configSchema['fields'] as List<dynamic>?;
      if (fieldsList != null) {
        for (final field in fieldsList) {
          if (field is Map<String, dynamic>) {
            final isRequired = field['required'] as bool? ?? false;
            if (isRequired) {
              fields.add(field['nombre'] as String? ?? '');
            }
          }
        }
      }
    }
    return fields.where((f) => f.isNotEmpty).toList();
  }
}

