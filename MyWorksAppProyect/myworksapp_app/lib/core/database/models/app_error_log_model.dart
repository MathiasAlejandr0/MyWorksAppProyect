class AppErrorLogModel {
  final String id;
  final String? userId;
  final String errorType;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;
  final String status; // new, acknowledged, resolved, ignored
  final String? appVersion;
  final String? platform;
  final DateTime createdAt;

  AppErrorLogModel({
    required this.id,
    this.userId,
    this.errorType = 'error',
    required this.message,
    this.stackTrace,
    this.metadata,
    this.status = 'nuevo',
    this.appVersion,
    this.platform,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_usuario': userId,
      'tipo_error': errorType,
      'mensaje': message,
      'traza_pila': stackTrace,
      'metadatos': metadata,
      'estado': status,
      'version_app': appVersion,
      'plataforma': platform,
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory AppErrorLogModel.fromMap(Map<String, dynamic> map) {
    return AppErrorLogModel(
      id: map['id'] as String,
      userId: map['id_usuario'] as String?,
      errorType: map['tipo_error'] as String? ?? 'error',
      message: map['mensaje'] as String,
      stackTrace: map['traza_pila'] as String?,
      metadata: map['metadatos'] is Map
          ? Map<String, dynamic>.from(map['metadatos'] as Map)
          : null,
      status: map['estado'] as String? ?? 'nuevo',
      appVersion: map['version_app'] as String?,
      platform: map['plataforma'] as String?,
      createdAt: DateTime.parse(map['creado_en'] as String),
    );
  }

  AppErrorLogModel copyWith({
    String? status,
  }) {
    return AppErrorLogModel(
      id: id,
      userId: userId,
      errorType: errorType,
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
      status: status ?? this.status,
      appVersion: appVersion,
      platform: platform,
      createdAt: createdAt,
    );
  }
}
