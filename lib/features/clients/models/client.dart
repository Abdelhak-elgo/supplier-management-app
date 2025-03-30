class Client {
  final int? id;
  final String name;
  final String phone;
  final String city;
  final String notes;
  final String type;
  final DateTime createdAt;

  Client({
    this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.notes,
    required this.type,
    required this.createdAt,
  });

  factory Client.empty() {
    return Client(
      name: '',
      phone: '',
      city: '',
      notes: '',
      type: 'Regular',
      createdAt: DateTime.now(),
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? city,
    String? notes,
    String? type,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'city': city,
      'notes': notes,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMapForDb() {
    final map = {
      'name': name,
      'phone': phone,
      'city': city,
      'notes': notes,
      'type': type,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      city: map['city'] ?? '',
      notes: map['notes'] ?? '',
      type: map['type'] ?? 'Regular',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Client{id: $id, name: $name, phone: $phone, city: $city, type: $type}';
  }
}
