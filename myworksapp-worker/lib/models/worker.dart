class Worker {
  int? id;
  String name;
  String email;
  String phone;
  String password;
  String profession;
  String? description;
  String? address;
  double? hourlyRate;
  String? profileImage;
  List<String> workImages;
  List<String> certificates;
  DateTime createdAt;
  bool isAvailable;

  Worker({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.profession,
    this.description,
    this.address,
    this.hourlyRate,
    this.profileImage,
    this.workImages = const [],
    this.certificates = const [],
    required this.createdAt,
    this.isAvailable = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'profession': profession,
      'description': description,
      'address': address,
      'hourlyRate': hourlyRate,
      'profileImage': profileImage,
      'workImages': workImages.join(','),
      'certificates': certificates.join(','),
      'createdAt': createdAt.toIso8601String(),
      'isAvailable': isAvailable ? 1 : 0,
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
      description: map['description'],
      address: map['address'],
      hourlyRate: map['hourlyRate'] != null ? map['hourlyRate'] * 1.0 : null,
      profileImage: map['profileImage'],
      workImages: map['workImages'] != null && map['workImages'] != ''
          ? map['workImages'].split(',')
          : [],
      certificates: map['certificates'] != null && map['certificates'] != ''
          ? map['certificates'].split(',')
          : [],
      createdAt: DateTime.parse(map['createdAt']),
      isAvailable: map['isAvailable'] == 1,
    );
  }

  Worker copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? profession,
    String? description,
    String? address,
    double? hourlyRate,
    String? profileImage,
    List<String>? workImages,
    List<String>? certificates,
    DateTime? createdAt,
    bool? isAvailable,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      profession: profession ?? this.profession,
      description: description ?? this.description,
      address: address ?? this.address,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      profileImage: profileImage ?? this.profileImage,
      workImages: workImages ?? this.workImages,
      certificates: certificates ?? this.certificates,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
