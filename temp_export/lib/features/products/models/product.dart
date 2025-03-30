class Product {
  final int? id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int quantity;
  final int minStockLevel;
  final String? barcode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.minStockLevel,
    this.barcode,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.empty() {
    return Product(
      name: '',
      description: '',
      category: '',
      price: 0.0,
      quantity: 0,
      minStockLevel: 5,
      createdAt: DateTime.now(),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    int? minStockLevel,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'quantity': quantity,
      'min_stock_level': minStockLevel,
      'barcode': barcode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMapForDb() {
    final map = {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'quantity': quantity,
      'min_stock_level': minStockLevel,
      'barcode': barcode,
    };

    if (id != null) {
      map['id'] = id;
    }

    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }

    return map;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: map['price'] != null ? map['price'].toDouble() : 0.0,
      quantity: map['quantity'] ?? 0,
      minStockLevel: map['min_stock_level'] ?? 5,
      barcode: map['barcode'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  bool get isLowStock => quantity <= minStockLevel;

  @override
  String toString() {
    return 'Product{id: $id, name: $name, price: $price, quantity: $quantity}';
  }
}
