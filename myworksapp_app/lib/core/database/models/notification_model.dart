class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'job_accepted', 'job_rejected', 'job_completed', 'new_message', 'new_job'
  final String title;
  final String body;
  final String? relatedId; // ID del trabajo o mensaje relacionado
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'relatedId': relatedId,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      relatedId: map['relatedId'] as String?,
      isRead: (map['isRead'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

