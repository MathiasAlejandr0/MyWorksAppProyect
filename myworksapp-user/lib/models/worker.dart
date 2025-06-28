class Worker {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String profession;
  final String? title;
  final String? titleInstitution;
  final int? titleYear;
  final String? description;
  final String? address;
  final double? hourlyRate;
  final bool isAvailable;
  final double? rating;
  final int? totalReviews;
  final String? profileImage;
  final List<String> workImages;
  final List<String> certificates;
  final DateTime createdAt;
  final DateTime? lastActive;

  Worker({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.profession,
    this.title,
    this.titleInstitution,
    this.titleYear,
    this.description,
    this.address,
    this.hourlyRate,
    this.isAvailable = false,
    this.rating,
    this.totalReviews,
    this.profileImage,
    this.workImages = const [],
    this.certificates = const [],
    required this.createdAt,
    this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'profession': profession,
      'title': title,
      'titleInstitution': titleInstitution,
      'titleYear': titleYear,
      'description': description,
      'address': address,
      'hourlyRate': hourlyRate,
      'isAvailable': isAvailable ? 1 : 0,
      'rating': rating,
      'totalReviews': totalReviews,
      'profileImage': profileImage,
      'workImages': workImages.join(','),
      'certificates': certificates.join(','),
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      password: map['password'],
      profession: map['profession'],
      title: map['title'],
      titleInstitution: map['titleInstitution'],
      titleYear: map['titleYear'],
      description: map['description'],
      address: map['address'],
      hourlyRate: map['hourlyRate'],
      isAvailable: map['isAvailable'] == 1,
      rating: map['rating'],
      totalReviews: map['totalReviews'],
      profileImage: map['profileImage'],
      workImages: map['workImages'] != null
          ? map['workImages'].split(',').where((s) => s.isNotEmpty).toList()
          : [],
      certificates: map['certificates'] != null
          ? map['certificates'].split(',').where((s) => s.isNotEmpty).toList()
          : [],
      createdAt: DateTime.parse(map['createdAt']),
      lastActive:
          map['lastActive'] != null ? DateTime.parse(map['lastActive']) : null,
    );
  }

  Worker copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? profession,
    String? title,
    String? titleInstitution,
    int? titleYear,
    String? description,
    String? address,
    double? hourlyRate,
    bool? isAvailable,
    double? rating,
    int? totalReviews,
    String? profileImage,
    List<String>? workImages,
    List<String>? certificates,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      profession: profession ?? this.profession,
      title: title ?? this.title,
      titleInstitution: titleInstitution ?? this.titleInstitution,
      titleYear: titleYear ?? this.titleYear,
      description: description ?? this.description,
      address: address ?? this.address,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      profileImage: profileImage ?? this.profileImage,
      workImages: workImages ?? this.workImages,
      certificates: certificates ?? this.certificates,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
