class PendingActionModel {
  final String id;
  final String userId;
  final String actionType; // 'create_job', 'update_job', 'send_message', 'update_profile'
  final String entityType;
  final String? entityId;
  final String data; // JSON string
  final String status; // 'pendiente_sync', 'sincronizando', 'sincronizado', 'fallido'
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  PendingActionModel({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.entityType,
    this.entityId,
    required this.data,
    this.status = 'pendiente_sync',
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_usuario': userId,
      'tipo_accion': actionType,
      'tipo_entidad': entityType,
      'id_entidad': entityId,
      'datos': data,
      'estado': status,
      'conteo_reintentos': retryCount,
      'mensaje_error': errorMessage,
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory PendingActionModel.fromMap(Map<String, dynamic> map) {
    return PendingActionModel(
      id: map['id'] as String,
      userId: map['id_usuario'] as String,
      actionType: map['tipo_accion'] as String,
      entityType: map['tipo_entidad'] as String,
      entityId: map['id_entidad'] as String?,
      data: map['datos'] as String,
      status: map['estado'] as String,
      retryCount: map['conteo_reintentos'] as int,
      errorMessage: map['mensaje_error'] as String?,
      createdAt: DateTime.parse(map['creado_en'] as String),
      updatedAt: DateTime.parse(map['actualizado_en'] as String),
    );
  }

  PendingActionModel copyWith({
    String? id,
    String? userId,
    String? actionType,
    String? entityType,
    String? entityId,
    String? data,
    String? status,
    int? retryCount,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PendingActionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pendiente_sync';
  bool get isSyncing => status == 'sincronizando';
  bool get isSynced => status == 'sincronizado';
  bool get hasFailed => status == 'fallido';
}

