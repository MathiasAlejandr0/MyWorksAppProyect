class UserModel {
  final String id;
  final String name;
  final String email;
  final String? password; // Hash de contraseña (nullable para usuarios existentes)
  final String role; // 'user' or 'worker'
  final String accountStatus; // 'active', 'suspended', 'blocked'
  final String? profilePhotoPath;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    required this.role,
    this.accountStatus = 'active',
    this.profilePhotoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'accountStatus': accountStatus,
      'profilePhotoPath': profilePhotoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String?,
      role: map['role'] as String,
      accountStatus: (map['accountStatus'] as String?) ?? 'active',
      profilePhotoPath: map['profilePhotoPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? accountStatus,
    String? profilePhotoPath,
    bool clearProfilePhoto = false,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      profilePhotoPath: clearProfilePhoto ? null : (profilePhotoPath ?? this.profilePhotoPath),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isActive => accountStatus == 'active';
  bool get isSuspended => accountStatus == 'suspended';
  bool get isBlocked => accountStatus == 'blocked';
}

