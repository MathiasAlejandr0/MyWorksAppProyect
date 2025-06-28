class WorkerNotification {
  final int? id;
  final int workerId;
  final String title;
  final String message;
  final String type; // 'request', 'review', 'system'
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  WorkerNotification({
    this.id,
    required this.workerId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'data': data != null ? data.toString() : null,
    };
  }

  factory WorkerNotification.fromMap(Map<String, dynamic> map) {
    return WorkerNotification(
      id: map['id'],
      workerId: map['workerId'],
      title: map['title'],
      message: map['message'],
      type: map['type'],
      isRead: map['isRead'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }
}
