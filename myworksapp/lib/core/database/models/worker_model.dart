class WorkerModel {
  final String userId;
  final String profession;
  final String? description;
  final double rating;
  final bool isAvailable;
  final double visitFee;
  final String serviceCategory;

  WorkerModel({
    required this.userId,
    required this.profession,
    this.description,
    this.rating = 0.0,
    this.isAvailable = true,
    this.visitFee = 15000,
    this.serviceCategory = 'general',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'profession': profession,
      'description': description,
      'rating': rating,
      'isAvailable': isAvailable ? 1 : 0,
      'visitFee': visitFee,
      'serviceCategory': serviceCategory,
    };
  }

  factory WorkerModel.fromMap(Map<String, dynamic> map) {
    return WorkerModel(
      userId: map['userId'] as String,
      profession: map['profession'] as String,
      description: map['description'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      isAvailable: (map['isAvailable'] as int? ?? 0) == 1,
      visitFee: (map['visitFee'] as num?)?.toDouble() ?? 15000,
      serviceCategory: map['serviceCategory'] as String? ?? 'general',
    );
  }

  WorkerModel copyWith({
    String? userId,
    String? profession,
    String? description,
    double? rating,
    bool? isAvailable,
    double? visitFee,
    String? serviceCategory,
  }) {
    return WorkerModel(
      userId: userId ?? this.userId,
      profession: profession ?? this.profession,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      visitFee: visitFee ?? this.visitFee,
      serviceCategory: serviceCategory ?? this.serviceCategory,
    );
  }
}
