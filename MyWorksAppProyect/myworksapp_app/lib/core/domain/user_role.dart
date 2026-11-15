/// Roles de la aplicación.
///
/// Los valores de [dbValue] coinciden con la columna `perfiles.rol`
/// (`usuario` | `trabajador` | `administrador`). En la UI se usan las
/// etiquetas de negocio **Cliente** y **Especialista**.
enum UserRole {
  cliente,
  especialista,
  administrador;

  /// Código persistido en Supabase (`perfiles.rol`).
  String get dbValue {
    switch (this) {
      case UserRole.cliente:
        return 'usuario';
      case UserRole.especialista:
        return 'trabajador';
      case UserRole.administrador:
        return 'administrador';
    }
  }

  /// Etiqueta visible para el usuario final.
  String get label {
    switch (this) {
      case UserRole.cliente:
        return 'Cliente';
      case UserRole.especialista:
        return 'Especialista';
      case UserRole.administrador:
        return 'Administrador';
    }
  }

  /// Descripción corta para selectores de registro / login.
  String get description {
    switch (this) {
      case UserRole.cliente:
        return 'Busco servicios profesionales';
      case UserRole.especialista:
        return 'Ofrezco servicios profesionales';
      case UserRole.administrador:
        return 'Gestión y supervisión de la plataforma';
    }
  }

  bool get isCliente => this == UserRole.cliente;
  bool get isEspecialista => this == UserRole.especialista;
  bool get isAdministrador => this == UserRole.administrador;

  /// Roles que se pueden elegir en el registro público.
  static const List<UserRole> publicRoles = [
    UserRole.cliente,
    UserRole.especialista,
  ];

  /// Convierte un código de BD, alias en inglés o etiqueta a [UserRole].
  ///
  /// Valores desconocidos se tratan como [UserRole.cliente] para no bloquear
  /// la sesión; el registro público nunca puede producir administrador.
  static UserRole fromDb(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'trabajador':
      case 'worker':
      case 'especialista':
      case 'specialist':
        return UserRole.especialista;
      case 'administrador':
      case 'admin':
      case 'administrator':
        return UserRole.administrador;
      case 'usuario':
      case 'user':
      case 'cliente':
      case 'client':
      default:
        return UserRole.cliente;
    }
  }

  /// Nunca permite auto-asignarse administrador desde el registro público.
  static UserRole sanitizeForRegistration(UserRole? role) {
    if (role == UserRole.especialista) return UserRole.especialista;
    return UserRole.cliente;
  }
}
