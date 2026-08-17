/// Modelo para boosts
class BoostModel {
  final String id;
  final String workerId;
  final String boostType; // 'visibility', 'priority', 'featured'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  BoostModel({
    required this.id,
    required this.workerId,
    required this.boostType,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'boostType': boostType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BoostModel.fromMap(Map<String, dynamic> map) {
    return BoostModel(
      id: map['id'] as String,
      workerId: map['workerId'] as String,
      boostType: map['boostType'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

