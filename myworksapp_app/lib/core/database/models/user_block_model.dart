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
      'id_bloqueador': blockerId,
      'id_bloqueado': blockedUserId,
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory UserBlockModel.fromMap(Map<String, dynamic> map) {
    return UserBlockModel(
      id: map['id'] as String,
      blockerId: map['id_bloqueador'] as String,
      blockedUserId: map['id_bloqueado'] as String,
      createdAt: DateTime.parse(map['creado_en'] as String),
    );
  }
}

