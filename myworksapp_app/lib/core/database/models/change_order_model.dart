class ChangeOrderModel {
  final String id;
  final String jobId;
  final String workerId;
  final String tipo;
  final String titulo;
  final String descripcion;
  final int montoClp;
  final String estado;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime? respondedAt;

  ChangeOrderModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.montoClp,
    required this.estado,
    this.paymentId,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobId': jobId,
        'workerId': workerId,
        'tipo': tipo,
        'titulo': titulo,
        'descripcion': descripcion,
        'montoClp': montoClp,
        'estado': estado,
        'paymentId': paymentId,
        'createdAt': createdAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
      };

  factory ChangeOrderModel.fromMap(Map<String, dynamic> map) {
    return ChangeOrderModel(
      id: map['id'] as String,
      jobId: map['jobId'] as String,
      workerId: map['workerId'] as String,
      tipo: map['tipo'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      montoClp: (map['montoClp'] as num).toInt(),
      estado: map['estado'] as String,
      paymentId: map['paymentId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'] as String)
          : null,
    );
  }

  bool get isPendingClient => estado == 'pending_client';
  bool get isPaid => estado == 'paid';
}
