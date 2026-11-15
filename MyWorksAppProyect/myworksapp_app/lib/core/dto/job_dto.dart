/// DTO (Data Transfer Object) para Job
/// 
/// Preparado para comunicación con backend.
/// Diferente del modelo local (JobModel) porque puede tener campos adicionales
/// o diferentes según la API del servidor.
class JobDTO {
  final String id;
  final String userId;
  final String? workerId;
  final String serviceId;
  final String status;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? description;
  final DateTime? scheduledDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos adicionales que pueden venir del servidor
  final Map<String, dynamic>? metadata;

  JobDTO({
    required this.id,
    required this.userId,
    this.workerId,
    required this.serviceId,
    required this.status,
    required this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.scheduledDate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Convierte DTO a JSON para enviar al servidor
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'workerId': workerId,
      'serviceId': serviceId,
      'status': status,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Crea DTO desde JSON del servidor
  factory JobDTO.fromJson(Map<String, dynamic> json) {
    return JobDTO(
      id: json['id'] as String,
      userId: json['userId'] as String,
      workerId: json['workerId'] as String?,
      serviceId: json['serviceId'] as String,
      status: json['status'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

