class Review {
  final int? id;
  final int workerId;
  final String clientName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    this.id,
    required this.workerId,
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'clientName': clientName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      workerId: map['workerId'],
      clientName: map['clientName'],
      rating: map['rating'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
