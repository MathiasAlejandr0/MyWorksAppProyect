class MessageModel {
  final String id;
  final String jobId;
  final String senderId;
  final String receiverId;
  final String content;
  final String type; // 'text' or 'image'
  final String? imagePath;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = 'text',
    this.imagePath,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'imagePath': imagePath,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      content: map['content'] as String,
      type: map['type'] as String? ?? 'text',
      imagePath: map['imagePath'] as String?,
      isRead: (map['isRead'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

