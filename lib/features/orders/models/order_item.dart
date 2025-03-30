class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final int quantity;
  final double pricePerUnit;
  final double subtotal;

  // Not stored in database directly, but useful for UI
  final String? productName;
  final String? productDescription;
  final String? productCategory;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.pricePerUnit,
    required this.subtotal,
    this.productName,
    this.productDescription,
    this.productCategory,
  });

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? quantity,
    double? pricePerUnit,
    double? subtotal,
    String? productName,
    String? productDescription,
    String? productCategory,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      subtotal: subtotal ?? this.subtotal,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productCategory: productCategory ?? this.productCategory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'subtotal': subtotal,
      'product_name': productName,
      'product_description': productDescription,
      'product_category': productCategory,
    };
  }

  Map<String, dynamic> toMapForDb() {
    final map = {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'subtotal': subtotal,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      pricePerUnit: map['price_per_unit'] != null
          ? map['price_per_unit'].toDouble()
          : 0.0,
      subtotal: map['subtotal'] != null ? map['subtotal'].toDouble() : 0.0,
      productName: map['product_name'],
      productDescription: map['product_description'],
      productCategory: map['product_category'],
    );
  }

  // Create an order item from a map with product details embedded
  factory OrderItem.fromProductMap(Map<String, dynamic> map, int orderId, int quantity) {
    final pricePerUnit = map['price'] != null ? map['price'].toDouble() : 0.0;
    return OrderItem(
      orderId: orderId,
      productId: map['id'],
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      subtotal: pricePerUnit * quantity,
      productName: map['name'],
      productDescription: map['description'],
      productCategory: map['category'],
    );
  }

  @override
  String toString() {
    return 'OrderItem{id: $id, orderId: $orderId, productId: $productId, productName: $productName, quantity: $quantity, subtotal: $subtotal}';
  }
}
