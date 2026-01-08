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
      'flagName': flagName,
      'isEnabled': isEnabled ? 1 : 0,
      'appVersion': appVersion,
      'role': role,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FeatureFlagModel.fromMap(Map<String, dynamic> map) {
    return FeatureFlagModel(
      id: map['id'] as String,
      flagName: map['flagName'] as String,
      isEnabled: (map['isEnabled'] as int? ?? 0) == 1,
      appVersion: map['appVersion'] as String?,
      role: map['role'] as String?,
      userId: map['userId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
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

