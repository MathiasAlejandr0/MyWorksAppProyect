class PortfolioItem {
  int? id;
  int workerId;
  String imagePath;
  String? description;
  DateTime createdAt;

  PortfolioItem({
    this.id,
    required this.workerId,
    required this.imagePath,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'imagePath': imagePath,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      id: map['id'],
      workerId: map['workerId'],
      imagePath: map['imagePath'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
