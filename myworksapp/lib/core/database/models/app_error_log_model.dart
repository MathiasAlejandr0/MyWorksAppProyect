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
    this.status = 'new',
    this.appVersion,
    this.platform,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace,
      'metadata': metadata,
      'status': status,
      'appVersion': appVersion,
      'platform': platform,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppErrorLogModel.fromMap(Map<String, dynamic> map) {
    return AppErrorLogModel(
      id: map['id'] as String,
      userId: map['userId'] as String?,
      errorType: map['errorType'] as String? ?? 'error',
      message: map['message'] as String,
      stackTrace: map['stackTrace'] as String?,
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      status: map['status'] as String? ?? 'new',
      appVersion: map['appVersion'] as String?,
      platform: map['platform'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
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
