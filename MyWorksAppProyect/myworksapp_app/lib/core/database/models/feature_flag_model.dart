/// Modelo para feature flags
class FeatureFlagModel {
  final String id;
  final String flagName;
  final bool isEnabled;
  final String? appVersion; // null = todas las versiones
  final String? role; // null = todos los roles
  final String? userId; // null = todos los usuarios
  final DateTime createdAt;
  final DateTime updatedAt;

  FeatureFlagModel({
    required this.id,
    required this.flagName,
    required this.isEnabled,
    this.appVersion,
    this.role,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_bandera': flagName,
      'habilitada': isEnabled ? 1 : 0,
      'version_app': appVersion,
      'rol': role,
      'id_usuario': userId,
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory FeatureFlagModel.fromMap(Map<String, dynamic> map) {
    return FeatureFlagModel(
      id: map['id'] as String,
      flagName: map['nombre_bandera'] as String,
      isEnabled: (map['habilitada'] as int? ?? 0) == 1,
      appVersion: map['version_app'] as String?,
      role: map['rol'] as String?,
      userId: map['id_usuario'] as String?,
      createdAt: DateTime.parse(map['creado_en'] as String),
      updatedAt: DateTime.parse(map['actualizado_en'] as String),
    );
  }

  FeatureFlagModel copyWith({
    String? id,
    String? flagName,
    bool? isEnabled,
    String? appVersion,
    String? role,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeatureFlagModel(
      id: id ?? this.id,
      flagName: flagName ?? this.flagName,
      isEnabled: isEnabled ?? this.isEnabled,
      appVersion: appVersion ?? this.appVersion,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

