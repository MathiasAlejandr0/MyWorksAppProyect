class Request {
  int? id;
  int workerId;
  String userName;
  String userContact;
  String service;
  String description;
  DateTime requestedAt;
  String status; // pendiente, aceptada, rechazada, completada

  Request({
    this.id,
    required this.workerId,
    required this.userName,
    required this.userContact,
    required this.service,
    required this.description,
    required this.requestedAt,
    this.status = 'pendiente',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'userName': userName,
      'userContact': userContact,
      'service': service,
      'description': description,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status,
    };
  }

  factory Request.fromMap(Map<String, dynamic> map) {
    return Request(
      id: map['id'],
      workerId: map['workerId'],
      userName: map['userName'],
      userContact: map['userContact'],
      service: map['service'],
      description: map['description'],
      requestedAt: DateTime.parse(map['requestedAt']),
      status: map['status'],
    );
  }

  Request copyWith({
    int? id,
    int? workerId,
    String? userName,
    String? userContact,
    String? service,
    String? description,
    DateTime? requestedAt,
    String? status,
  }) {
    return Request(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      userName: userName ?? this.userName,
      userContact: userContact ?? this.userContact,
      service: service ?? this.service,
      description: description ?? this.description,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
    );
  }
}
