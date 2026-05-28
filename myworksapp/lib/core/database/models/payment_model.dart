/// Modelo para pagos (preparado para futuro)
/// 
/// Estados:
/// - pending: Pago pendiente
/// - authorized: Pago autorizado (en escrow)
/// - held: Pago retenido (disputa)
/// - released: Pago liberado al trabajador
/// - refunded: Pago reembolsado
class PaymentModel {
  final String id;
  final String jobId;
  final String? changeOrderId;
  final String paymentType; // primary | change_order | overtime
  final double amount;
  final String currency;
  final String status; // 'pending', 'authorized', 'held', 'released', 'refunded'
  final String? paymentMethod; // 'card', 'cash', 'transfer', etc.
  final String? transactionId; // ID de transacción externa
  final DateTime? authorizedAt;
  final DateTime? releasedAt;
  final DateTime? refundedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.jobId,
    this.changeOrderId,
    this.paymentType = 'primary',
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
      'jobId': jobId,
      'changeOrderId': changeOrderId,
      'paymentType': paymentType,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'authorizedAt': authorizedAt?.toIso8601String(),
      'releasedAt': releasedAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      changeOrderId: map['changeOrderId'] as String?,
      paymentType: map['paymentType'] as String? ?? 'primary',
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'CLP',
      status: map['status'] as String,
      paymentMethod: map['paymentMethod'] as String?,
      transactionId: map['transactionId'] as String?,
      authorizedAt: map['authorizedAt'] != null
          ? DateTime.parse(map['authorizedAt'] as String)
          : null,
      releasedAt: map['releasedAt'] != null
          ? DateTime.parse(map['releasedAt'] as String)
          : null,
      refundedAt: map['refundedAt'] != null
          ? DateTime.parse(map['refundedAt'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
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

