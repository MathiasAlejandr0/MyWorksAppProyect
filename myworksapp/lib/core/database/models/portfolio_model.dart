class PortfolioModel {
  final String id;
  final String workerId;
  final String photoPath;
  final String? description;
  final DateTime createdAt;

  PortfolioModel({
    required this.id,
    required this.workerId,
    required this.photoPath,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'photoPath': photoPath,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PortfolioModel.fromMap(Map<String, dynamic> map) {
    return PortfolioModel(
      id: map['id'] as String,
      workerId: map['workerId'] as String,
      photoPath: map['photoPath'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

