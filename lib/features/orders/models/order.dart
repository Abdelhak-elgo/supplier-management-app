class Order {
  final int? id;
  final int clientId;
  final DateTime orderDate;
  final String status;
  final double subtotal;
  final double total;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Not stored in database, but useful for UI
  final String? clientName;

  Order({
    this.id,
    required this.clientId,
    required this.orderDate,
    required this.status,
    required this.subtotal,
    required this.total,
    required this.notes,
    required this.createdAt,
    this.updatedAt,
    this.clientName,
  });

  factory Order.empty() {
    return Order(
      clientId: 0,
      orderDate: DateTime.now(),
      status: 'New',
      subtotal: 0.0,
      total: 0.0,
      notes: '',
      createdAt: DateTime.now(),
    );
  }

  Order copyWith({
    int? id,
    int? clientId,
    DateTime? orderDate,
    String? status,
    double? subtotal,
    double? total,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientName,
  }) {
    return Order(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientName: clientName ?? this.clientName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'client_name': clientName,
    };
  }

  Map<String, dynamic> toMapForDb() {
    final map = {
      'client_id': clientId,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
    };

    if (id != null) {
      map['id'] = id;
    }

    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }

    return map;
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      clientId: map['client_id'],
      orderDate: map['order_date'] != null
          ? DateTime.parse(map['order_date'])
          : DateTime.now(),
      status: map['status'] ?? 'New',
      subtotal: map['subtotal'] != null ? map['subtotal'].toDouble() : 0.0,
      total: map['total'] != null ? map['total'].toDouble() : 0.0,
      notes: map['notes'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      clientName: map['client_name'],
    );
  }

  @override
  String toString() {
    return 'Order{id: $id, clientId: $clientId, clientName: $clientName, status: $status, total: $total}';
  }
}
