import '../../domain/user_role.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? password; // Hash de contraseña (nullable para usuarios existentes)
  final String role; // usuario | trabajador | administrador
  final String accountStatus; // activo | suspendido | bloqueado
  final String? profilePhotoPath;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    required this.role,
    this.accountStatus = 'activo',
    this.profilePhotoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'correo': email,
      'password': password,
      'rol': role,
      'estado_cuenta': accountStatus,
      'ruta_foto_perfil': profilePhotoPath,
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['nombre'] as String,
      email: map['correo'] as String,
      password: map['password'] as String?,
      role: map['rol'] as String,
      accountStatus: (map['estado_cuenta'] as String?) ?? 'activo',
      profilePhotoPath: map['ruta_foto_perfil'] as String?,
      createdAt: DateTime.parse(map['creado_en'] as String),
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

  bool get isActive => accountStatus == 'activo';
  bool get isSuspended => accountStatus == 'suspendido';
  bool get isBlocked => accountStatus == 'bloqueado';

  /// Rol tipado. El string [role] se mantiene para compatibilidad con la BD.
  UserRole get userRole => UserRole.fromDb(role);
}

