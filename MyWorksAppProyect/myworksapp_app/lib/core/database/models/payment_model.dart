import '../../domain/pricing_constants.dart';

/// Modelo de pagos (estados ES en BD).
///
/// Estados: pendiente | autorizado | retenido | liberado | reembolsado
/// Tipos: principal | orden_cambio | horas_extra
///
/// Nota: la pasarela real aún no está integrada; el flujo es simulación de escrow.
class PaymentModel {
  final String id;
  final String jobId;
  final String? changeOrderId;
  final String paymentType;
  final double amount;
  final String currency;
  final String status;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime? authorizedAt;
  final DateTime? releasedAt;
  final DateTime? refundedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.jobId,
    this.changeOrderId,
    this.paymentType = PricingConstants.paymentTypePrimary,
    required this.amount,
    this.currency = 'CLP',
    required this.status,
    this.paymentMethod,
    this.transactionId,
    this.authorizedAt,
    this.releasedAt,
    this.refundedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_trabajo': jobId,
      'id_orden_cambio': changeOrderId,
      'tipo_pago': paymentType,
      'monto': amount,
      'moneda': currency,
      'estado': status,
      'metodo_pago': paymentMethod,
      'id_transaccion': transactionId,
      'autorizado_en': authorizedAt?.toIso8601String(),
      'liberado_en': releasedAt?.toIso8601String(),
      'reembolsado_en': refundedAt?.toIso8601String(),
      'creado_en': createdAt.toIso8601String(),
      'actualizado_en': updatedAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      jobId: map['id_trabajo'] as String,
      changeOrderId: map['id_orden_cambio'] as String?,
      paymentType: map['tipo_pago'] as String? ??
          PricingConstants.paymentTypePrimary,
      amount: (map['monto'] as num).toDouble(),
      currency: map['moneda'] as String? ?? 'CLP',
      status: map['estado'] as String,
      paymentMethod: map['metodo_pago'] as String?,
      transactionId: map['id_transaccion'] as String?,
      authorizedAt: map['autorizado_en'] != null
          ? DateTime.parse(map['autorizado_en'] as String)
          : null,
      releasedAt: map['liberado_en'] != null
          ? DateTime.parse(map['liberado_en'] as String)
          : null,
      refundedAt: map['reembolsado_en'] != null
          ? DateTime.parse(map['reembolsado_en'] as String)
          : null,
      createdAt: DateTime.parse(map['creado_en'] as String),
      updatedAt: DateTime.parse(map['actualizado_en'] as String),
    );
  }

  PaymentModel copyWith({
    String? id,
    String? jobId,
    String? changeOrderId,
    String? paymentType,
    double? amount,
    String? currency,
    String? status,
    String? paymentMethod,
    String? transactionId,
    DateTime? authorizedAt,
    DateTime? releasedAt,
    DateTime? refundedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      changeOrderId: changeOrderId ?? this.changeOrderId,
      paymentType: paymentType ?? this.paymentType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      authorizedAt: authorizedAt ?? this.authorizedAt,
      releasedAt: releasedAt ?? this.releasedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

