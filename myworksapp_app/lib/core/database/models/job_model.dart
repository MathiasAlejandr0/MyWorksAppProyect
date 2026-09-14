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
      'id_usuario': userId,
      'id_trabajador': workerId,
      'id_servicio': serviceId,
      'estado': status,
      'direccion': address,
      'latitud': latitude,
      'longitud': longitude,
      'descripcion': description,
      'fecha_programada': scheduledDate?.toIso8601String(),
      'metadatos_servicio': serviceMetadata != null ? jsonEncode(serviceMetadata) : null,
      'modalidad_cobro': pricingMode,
      'estado_pago': paymentStatus,
      'id_comuna': comunaId,
      'instantanea_precio': pricingSnapshot != null ? jsonEncode(pricingSnapshot) : null,
      'id_sku_servicio': serviceSkuId,
      'horas_bloque': hourlyBlockHours,
      'id_cotizacion_seleccionada': selectedQuoteId,
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? metadata;
    if (map['metadatos_servicio'] != null) {
      try {
        metadata = jsonDecode(map['metadatos_servicio'] as String) as Map<String, dynamic>;
      } catch (_) {
        metadata = null;
      }
    }

    Map<String, dynamic>? snapshot;
    if (map['instantanea_precio'] != null) {
      try {
        snapshot = jsonDecode(map['instantanea_precio'] as String) as Map<String, dynamic>;
      } catch (_) {
        snapshot = null;
      }
    }

    return JobModel(
      id: map['id'] as String,
      userId: map['id_usuario'] as String,
      workerId: map['id_trabajador'] as String?,
      serviceId: map['id_servicio'] as String,
      status: map['estado'] as String,
      address: map['direccion'] as String,
      latitude: map['latitud'] != null ? (map['latitud'] as num).toDouble() : null,
      longitude: map['longitud'] != null ? (map['longitud'] as num).toDouble() : null,
      description: map['descripcion'] as String?,
      scheduledDate: map['fecha_programada'] != null
          ? DateTime.parse(map['fecha_programada'] as String)
          : null,
      serviceMetadata: metadata,
      pricingMode: map['modalidad_cobro'] as String? ?? PricingConstants.modeLegacy,
      paymentStatus: map['estado_pago'] as String? ?? PricingConstants.paymentNone,
      comunaId: map['id_comuna'] as String?,
      pricingSnapshot: snapshot,
      serviceSkuId: map['id_sku_servicio'] as String?,
      hourlyBlockHours: map['horas_bloque'] as int?,
      selectedQuoteId: map['id_cotizacion_seleccionada'] as String?,
      createdAt: DateTime.parse(map['creado_en'] as String),
      updatedAt: DateTime.parse(map['actualizado_en'] as String),
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
