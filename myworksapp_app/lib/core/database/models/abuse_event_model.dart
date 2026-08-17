/// Modelo para eventos de abuso
class AbuseEventModel {
  final String id;
  final String userId;
  final String abuseType; // 'excessive_jobs', 'excessive_rejections', 'excessive_cancellations'
  final int count;
  final DateTime detectedAt;
  final String? actionTaken; // 'shadow_ban', 'trust_penalty', 'temporary_ban'
  final DateTime? actionTakenAt;
  final bool isResolved;

  AbuseEventModel({
    required this.id,
    required this.userId,
    required this.abuseType,
    required this.count,
    required this.detectedAt,
    this.actionTaken,
    this.actionTakenAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'abuseType': abuseType,
      'count': count,
      'detectedAt': detectedAt.toIso8601String(),
      'actionTaken': actionTaken,
      'actionTakenAt': actionTakenAt?.toIso8601String(),
      'isResolved': isResolved ? 1 : 0,
    };
  }

  factory AbuseEventModel.fromMap(Map<String, dynamic> map) {
    return AbuseEventModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      abuseType: map['abuseType'] as String,
      count: map['count'] as int,
      detectedAt: DateTime.parse(map['detectedAt'] as String),
      actionTaken: map['actionTaken'] as String?,
      actionTakenAt: map['actionTakenAt'] != null
          ? DateTime.parse(map['actionTakenAt'] as String)
          : null,
      isResolved: (map['isResolved'] as int? ?? 0) == 1,
    );
  }

  AbuseEventModel copyWith({
    String? id,
    String? userId,
    String? abuseType,
    int? count,
    DateTime? detectedAt,
    String? actionTaken,
    DateTime? actionTakenAt,
    bool? isResolved,
  }) {
    return AbuseEventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      abuseType: abuseType ?? this.abuseType,
      count: count ?? this.count,
      detectedAt: detectedAt ?? this.detectedAt,
      actionTaken: actionTaken ?? this.actionTaken,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

