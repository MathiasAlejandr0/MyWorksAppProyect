class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'job_accepted', 'job_rejected', 'job_completed', 'new_message', 'new_job'
  final String title;
  final String body;
  final String? relatedId; // ID del trabajo o mensaje relacionado
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_usuario': userId,
      'tipo': type,
      'titulo': title,
      'cuerpo': body,
      'id_relacionado': relatedId,
      'leido': isRead ? 1 : 0,
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['id_usuario'] as String,
      type: map['tipo'] as String,
      title: map['titulo'] as String,
      body: map['cuerpo'] as String,
      relatedId: map['id_relacionado'] as String?,
      isRead: (map['leido'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['creado_en'] as String),
    );
  }
}

