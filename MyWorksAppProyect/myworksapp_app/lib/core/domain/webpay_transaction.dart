/// Respuesta de `webpay-create`.
class WebpayTransactionResponse {
  const WebpayTransactionResponse({
    required this.token,
    required this.url,
    required this.buyOrder,
    this.paymentId,
    this.redirectUrl,
  });

  final String token;
  final String url;
  final String buyOrder;
  final String? paymentId;

  /// Handoff GET. Transbank recibe token_ws en la query.
  final String? redirectUrl;

  factory WebpayTransactionResponse.fromMap(Map<String, dynamic> map) {
    final token = map['token']?.toString() ?? '';
    final url = map['url']?.toString() ?? '';
    final buyOrder = map['buyOrder']?.toString() ??
        map['buy_order']?.toString() ??
        '';
    final redirect = map['redirectUrl']?.toString();
    final handoff = redirect != null && redirect.isNotEmpty ? redirect : null;
    if (buyOrder.isEmpty || (handoff == null && (token.isEmpty || url.isEmpty))) {
      throw const FormatException('Respuesta Webpay incompleta');
    }
    return WebpayTransactionResponse(
      token: token,
      url: url,
      buyOrder: buyOrder,
      paymentId: map['paymentId']?.toString(),
      redirectUrl: handoff,
    );
  }
}

/// Resultado de `webpay-commit`.
class WebpayCommitResult {
  const WebpayCommitResult({
    required this.approved,
    required this.paymentStatus,
    this.jobStatus,
    this.jobId,
    this.paymentId,
    this.buyOrder,
    this.responseCode,
    this.message,
  });

  final bool approved;

  /// `ESCROW` cuando los fondos quedan en garantía (HOLD).
  final String paymentStatus;

  /// `PAID_PENDING_EXECUTION` cuando el trabajo pasó a pendiente de ejecución.
  final String? jobStatus;
  final String? jobId;
  final String? paymentId;
  final String? buyOrder;
  final int? responseCode;
  final String? message;

  bool get rejected => !approved;

  factory WebpayCommitResult.fromMap(Map<String, dynamic> map) {
    final code = map['responseCode'] ?? map['response_code'];
    return WebpayCommitResult(
      approved: map['approved'] == true || map['ok'] == true,
      paymentStatus: map['paymentStatus']?.toString() ??
          (map['approved'] == true ? 'ESCROW' : 'REJECTED'),
      jobStatus: map['jobStatus']?.toString(),
      jobId: map['jobId']?.toString(),
      paymentId: map['paymentId']?.toString(),
      buyOrder: map['buyOrder']?.toString(),
      responseCode: code is num ? code.toInt() : int.tryParse('$code'),
      message: map['error']?.toString() ?? map['message']?.toString(),
    );
  }
}
