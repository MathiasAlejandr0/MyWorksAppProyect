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

  /// Nombre y foto públicos. No trae correo ni fecha real.
  factory UserModel.publicCard(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: (map['nombre'] as String?) ?? '',
      email: '',
      role: (map['rol'] as String?) ?? 'usuario',
      profilePhotoPath: map['ruta_foto_perfil'] as String?,
      createdAt: DateTime.utc(2020),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Perfil sin id');
    }
    return UserModel(
      id: id,
      name: _text(map['nombre'], fallback: 'Usuario'),
      email: _text(map['correo']),
      password: map['password'] is String ? map['password'] as String : null,
      role: _text(map['rol'], fallback: 'usuario'),
      accountStatus: _text(map['estado_cuenta'], fallback: 'activo'),
      profilePhotoPath: map['ruta_foto_perfil'] is String
          ? map['ruta_foto_perfil'] as String
          : null,
      createdAt: _createdAt(map['creado_en']),
    );
  }

  /// Correo y fecha pueden venir nulos o con otro tipo. Eso no debe impedir
  /// entrar: el rol y el nombre alcanzan para abrir la sesión.
  static String _text(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    return fallback;
  }

  static DateTime _createdAt(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));
      if (parsed != null) return parsed.toUtc();
    }
    return DateTime.now().toUtc();
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

