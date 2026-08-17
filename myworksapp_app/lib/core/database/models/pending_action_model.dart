class PendingActionModel {
  final String id;
  final String userId;
  final String actionType; // 'create_job', 'update_job', 'send_message', 'update_profile'
  final String entityType;
  final String? entityId;
  final String data; // JSON string
  final String status; // 'pending_sync', 'syncing', 'synced', 'failed'
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
    this.status = 'pending_sync',
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'actionType': actionType,
      'entityType': entityType,
      'entityId': entityId,
      'data': data,
      'status': status,
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PendingActionModel.fromMap(Map<String, dynamic> map) {
    return PendingActionModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      actionType: map['actionType'] as String,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String?,
      data: map['data'] as String,
      status: map['status'] as String,
      retryCount: map['retryCount'] as int,
      errorMessage: map['errorMessage'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
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

  bool get isPending => status == 'pending_sync';
  bool get isSyncing => status == 'syncing';
  bool get isSynced => status == 'synced';
  bool get hasFailed => status == 'failed';
}

