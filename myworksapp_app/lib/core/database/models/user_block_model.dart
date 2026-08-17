class UserBlockModel {
  final String id;
  final String blockerId;
  final String blockedUserId;
  final DateTime createdAt;

  UserBlockModel({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserBlockModel.fromMap(Map<String, dynamic> map) {
    return UserBlockModel(
      id: map['id'] as String,
      blockerId: map['blockerId'] as String,
      blockedUserId: map['blockedUserId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

