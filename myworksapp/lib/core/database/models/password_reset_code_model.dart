class PasswordResetCodeModel {
  final String id;
  final String userId;
  final String code;
  final String email;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  PasswordResetCodeModel({
    required this.id,
    required this.userId,
    required this.code,
    required this.email,
    required this.expiresAt,
    required this.isUsed,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'code': code,
      'email': email,
      'expiresAt': expiresAt.toIso8601String(),
      'isUsed': isUsed ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PasswordResetCodeModel.fromMap(Map<String, dynamic> map) {
    return PasswordResetCodeModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      code: map['code'] as String,
      email: map['email'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      isUsed: (map['isUsed'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;
}

