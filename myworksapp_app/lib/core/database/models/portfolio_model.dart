class PortfolioModel {
  final String id;
  final String workerId;
  final String photoPath;
  final String? description;
  final DateTime createdAt;
  final String mediaType;

  PortfolioModel({
    required this.id,
    required this.workerId,
    required this.photoPath,
    this.description,
    required this.createdAt,
    this.mediaType = 'foto',
  });

  bool get isDemoAsset => photoPath.startsWith('demo:');
  bool get isVideo => mediaType == 'video';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_trabajador': workerId,
      'ruta_foto': photoPath,
      'descripcion': description,
      'creado_en': createdAt.toIso8601String(),
      'tipo_medio': mediaType,
    };
  }

  factory PortfolioModel.fromMap(Map<String, dynamic> map) {
    return PortfolioModel(
      id: map['id'] as String,
      workerId: map['id_trabajador'] as String,
      photoPath: map['ruta_foto'] as String,
      description: map['descripcion'] as String?,
      createdAt: DateTime.parse(map['creado_en'] as String),
      mediaType: map['tipo_medio'] as String? ?? 'foto',
    );
  }
}
