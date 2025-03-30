import 'package:supplier_management/core/utils/date_formatter.dart';

class SalesReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalSales;
  final int totalOrders;
  final int cancelledOrders;
  final List<ProductSales> topProducts;
  final List<ClientSales> topClients;
  final List<DailySales> dailySales;

  SalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.totalOrders,
    required this.cancelledOrders,
    required this.topProducts,
    required this.topClients,
    required this.dailySales,
  });

  factory SalesReport.empty() {
    final now = DateTime.now();
    return SalesReport(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      totalSales: 0.0,
      totalOrders: 0,
      cancelledOrders: 0,
      topProducts: [],
      topClients: [],
      dailySales: [],
    );
  }

  String get period {
    return '${DateFormatter.formatDate(startDate)} - ${DateFormatter.formatDate(endDate)}';
  }

  double get averageOrderValue {
    if (totalOrders == 0) return 0.0;
    return totalSales / totalOrders;
  }

  double get cancelledRate {
    if (totalOrders == 0) return 0.0;
    return cancelledOrders / totalOrders * 100;
  }
}

class ProductSales {
  final int productId;
  final String productName;
  final int quantity;
  final double revenue;

  ProductSales({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
  });

  factory ProductSales.fromMap(Map<String, dynamic> map) {
    return ProductSales(
      productId: map['product_id'] as int,
      productName: map['product_name'] as String? ?? 'Unknown Product',
      quantity: map['quantity'] as int? ?? 0,
      revenue: map['revenue'] != null ? (map['revenue'] as num).toDouble() : 0.0,
    );
  }

  double get averagePrice {
    if (quantity == 0) return 0.0;
    return revenue / quantity;
  }
}

class ClientSales {
  final int clientId;
  final String clientName;
  final int orderCount;
  final double totalSpent;

  ClientSales({
    required this.clientId,
    required this.clientName,
    required this.orderCount,
    required this.totalSpent,
  });

  factory ClientSales.fromMap(Map<String, dynamic> map) {
    return ClientSales(
      clientId: map['client_id'] as int,
      clientName: map['client_name'] as String? ?? 'Unknown Client',
      orderCount: map['order_count'] as int? ?? 0,
      totalSpent: map['total_spent'] != null ? (map['total_spent'] as num).toDouble() : 0.0,
    );
  }

  double get averageOrderValue {
    if (orderCount == 0) return 0.0;
    return totalSpent / orderCount;
  }
}

class DailySales {
  final DateTime date;
  final double sales;
  final int orderCount;

  DailySales({
    required this.date,
    required this.sales,
    required this.orderCount,
  });

  factory DailySales.fromMap(Map<String, dynamic> map) {
    return DailySales(
      date: DateTime.parse(map['date'] as String),
      sales: map['sales'] != null ? (map['sales'] as num).toDouble() : 0.0,
      orderCount: map['order_count'] as int? ?? 0,
    );
  }

  String get formattedDate => DateFormatter.formatDate(date);
}
