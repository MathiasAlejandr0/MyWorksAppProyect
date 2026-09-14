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
        'id_trabajo': jobId,
        'id_trabajador': workerId,
        'tipo': tipo,
        'titulo': titulo,
        'descripcion': descripcion,
        'monto_clp': montoClp,
        'estado': estado,
        'id_pago': paymentId,
        'creado_en': createdAt.toIso8601String(),
        'respondido_en': respondedAt?.toIso8601String(),
      };

  factory ChangeOrderModel.fromMap(Map<String, dynamic> map) {
    return ChangeOrderModel(
      id: map['id'] as String,
      jobId: map['id_trabajo'] as String,
      workerId: map['id_trabajador'] as String,
      tipo: map['tipo'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      montoClp: (map['monto_clp'] as num).toInt(),
      estado: map['estado'] as String,
      paymentId: map['id_pago'] as String?,
      createdAt: DateTime.parse(map['creado_en'] as String),
      respondedAt: map['respondido_en'] != null
          ? DateTime.parse(map['respondido_en'] as String)
          : null,
    );
  }

  bool get isPendingClient => estado == 'pendiente_cliente';
  bool get isPaid => estado == 'pagada';
}
