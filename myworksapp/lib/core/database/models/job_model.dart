import 'dart:convert';

import '../../domain/pricing_constants.dart';

class JobModel {
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
  final Map<String, dynamic>? serviceMetadata;
  final String pricingMode;
  final String paymentStatus;
  final String? comunaId;
  final Map<String, dynamic>? pricingSnapshot;
  final String? serviceSkuId;
  final int? hourlyBlockHours;
  final String? selectedQuoteId;
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
    this.pricingMode = PricingConstants.modeLegacy,
    this.paymentStatus = PricingConstants.paymentNone,
    this.comunaId,
    this.pricingSnapshot,
    this.serviceSkuId,
    this.hourlyBlockHours,
    this.selectedQuoteId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get requiresEscrow =>
      pricingMode == PricingConstants.modeFixedPrice ||
      pricingMode == PricingConstants.modeHourlyBlock ||
      pricingMode == PricingConstants.modeOpenQuote;

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
      'pricingMode': pricingMode,
      'paymentStatus': paymentStatus,
      'comunaId': comunaId,
      'pricingSnapshot': pricingSnapshot != null ? jsonEncode(pricingSnapshot) : null,
      'serviceSkuId': serviceSkuId,
      'hourlyBlockHours': hourlyBlockHours,
      'selectedQuoteId': selectedQuoteId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? metadata;
    if (map['serviceMetadata'] != null) {
      try {
        metadata = jsonDecode(map['serviceMetadata'] as String) as Map<String, dynamic>;
      } catch (_) {
        metadata = null;
      }
    }

    Map<String, dynamic>? snapshot;
    if (map['pricingSnapshot'] != null) {
      try {
        snapshot = jsonDecode(map['pricingSnapshot'] as String) as Map<String, dynamic>;
      } catch (_) {
        snapshot = null;
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
      pricingMode: map['pricingMode'] as String? ?? PricingConstants.modeLegacy,
      paymentStatus: map['paymentStatus'] as String? ?? PricingConstants.paymentNone,
      comunaId: map['comunaId'] as String?,
      pricingSnapshot: snapshot,
      serviceSkuId: map['serviceSkuId'] as String?,
      hourlyBlockHours: map['hourlyBlockHours'] as int?,
      selectedQuoteId: map['selectedQuoteId'] as String?,
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
    String? pricingMode,
    String? paymentStatus,
    String? comunaId,
    Map<String, dynamic>? pricingSnapshot,
    String? serviceSkuId,
    int? hourlyBlockHours,
    String? selectedQuoteId,
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
      pricingMode: pricingMode ?? this.pricingMode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      comunaId: comunaId ?? this.comunaId,
      pricingSnapshot: pricingSnapshot ?? this.pricingSnapshot,
      serviceSkuId: serviceSkuId ?? this.serviceSkuId,
      hourlyBlockHours: hourlyBlockHours ?? this.hourlyBlockHours,
      selectedQuoteId: selectedQuoteId ?? this.selectedQuoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
