class MessageModel {
  final String id;
  final String jobId;
  final String senderId;
  final String receiverId;
  final String content;
  final String type; // 'text' or 'image'
  final String? imagePath;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = 'texto',
    this.imagePath,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_trabajo': jobId,
      'id_remitente': senderId,
      'id_destinatario': receiverId,
      'contenido': content,
      'tipo': type,
      'ruta_imagen': imagePath,
      'leido': isRead ? 1 : 0,
      'creado_en': createdAt.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      jobId: map['id_trabajo'] as String,
      senderId: map['id_remitente'] as String,
      receiverId: map['id_destinatario'] as String,
      content: map['contenido'] as String,
      type: map['tipo'] as String? ?? 'texto',
      imagePath: map['ruta_imagen'] as String?,
      isRead: (map['leido'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['creado_en'] as String),
    );
  }
}

