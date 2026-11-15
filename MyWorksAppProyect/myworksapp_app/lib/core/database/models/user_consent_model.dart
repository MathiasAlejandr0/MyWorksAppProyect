/// Modelo para consentimientos GDPR del usuario
class UserConsentModel {
  final String id;
  final String userId;
  final String consentVersion; // Versión de los términos (ej: "1.0", "2.0")
  final bool accepted;
  final DateTime acceptedAt;
  final String? ipAddress; // Opcional, para auditoría
  final String? userAgent; // Opcional, para auditoría

  UserConsentModel({
    required this.id,
    required this.userId,
    required this.consentVersion,
    required this.accepted,
    required this.acceptedAt,
    this.ipAddress,
    this.userAgent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_usuario': userId,
      'version_consentimiento': consentVersion,
      'aceptado': accepted ? 1 : 0,
      'aceptado_en': acceptedAt.toIso8601String(),
      'direccion_ip': ipAddress,
      'agente_usuario': userAgent,
    };
  }

  factory UserConsentModel.fromMap(Map<String, dynamic> map) {
    return UserConsentModel(
      id: map['id'] as String,
      userId: map['id_usuario'] as String,
      consentVersion: map['version_consentimiento'] as String,
      accepted: (map['aceptado'] as int) == 1,
      acceptedAt: DateTime.parse(map['aceptado_en'] as String),
      ipAddress: map['direccion_ip'] as String?,
      userAgent: map['agente_usuario'] as String?,
    );
  }

  UserConsentModel copyWith({
    String? id,
    String? userId,
    String? consentVersion,
    bool? accepted,
    DateTime? acceptedAt,
    String? ipAddress,
    String? userAgent,
  }) {
    return UserConsentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      consentVersion: consentVersion ?? this.consentVersion,
      accepted: accepted ?? this.accepted,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
    );
  }
}

