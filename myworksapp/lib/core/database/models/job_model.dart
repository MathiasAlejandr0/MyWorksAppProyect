import 'dart:convert';

class JobModel {
  final String id;
  final String userId;
  final String? workerId;
  final String serviceId;
  final String status; // 'pending', 'accepted', 'in_progress', 'completed', 'cancelled'
  final String address;
  final double? latitude;
  final double? longitude;
  final String? description;
  final DateTime? scheduledDate;
  final Map<String, dynamic>? serviceMetadata; // Campos dinámicos del servicio
  final DateTime createdAt;
  final DateTime updatedAt;

  JobModel({
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
    this.serviceMetadata,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
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
      'serviceMetadata': serviceMetadata != null ? jsonEncode(serviceMetadata) : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? metadata;
    if (map['serviceMetadata'] != null) {
      try {
        metadata = jsonDecode(map['serviceMetadata'] as String) as Map<String, dynamic>;
      } catch (e) {
        metadata = null;
      }
    }
    
    return JobModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      workerId: map['workerId'] as String?,
      serviceId: map['serviceId'] as String,
      status: map['status'] as String,
      address: map['address'] as String,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      description: map['description'] as String?,
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.parse(map['scheduledDate'] as String)
          : null,
      serviceMetadata: metadata,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  JobModel copyWith({
    String? id,
    String? userId,
    String? workerId,
    String? serviceId,
    String? status,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    DateTime? scheduledDate,
    Map<String, dynamic>? serviceMetadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      serviceId: serviceId ?? this.serviceId,
      status: status ?? this.status,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      serviceMetadata: serviceMetadata ?? this.serviceMetadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

