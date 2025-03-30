class DashboardStats {
  final int totalProducts;
  final int lowStockProducts;
  final double totalSales;
  final int pendingOrders;
  final int completedOrders;
  final List<RecentOrder> recentOrders;

  DashboardStats({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalSales,
    required this.pendingOrders,
    required this.completedOrders,
    required this.recentOrders,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalProducts: 0,
      lowStockProducts: 0,
      totalSales: 0.0,
      pendingOrders: 0,
      completedOrders: 0,
      recentOrders: [],
    );
  }

  factory DashboardStats.fromMap(Map<String, dynamic> map, List<Map<String, dynamic>> recentOrdersMap) {
    return DashboardStats(
      totalProducts: map['totalProducts'] ?? 0,
      lowStockProducts: map['lowStockProducts'] ?? 0,
      totalSales: map['totalSales'] ?? 0.0,
      pendingOrders: map['pendingOrders'] ?? 0,
      completedOrders: map['completedOrders'] ?? 0,
      recentOrders: recentOrdersMap.map((orderMap) => RecentOrder.fromMap(orderMap)).toList(),
    );
  }
}

class RecentOrder {
  final int id;
  final String clientName;
  final DateTime orderDate;
  final String status;
  final double total;

  RecentOrder({
    required this.id,
    required this.clientName,
    required this.orderDate,
    required this.status,
    required this.total,
  });

  factory RecentOrder.fromMap(Map<String, dynamic> map) {
    return RecentOrder(
      id: map['id'] ?? 0,
      clientName: map['clientName'] ?? 'Unknown Client',
      orderDate: DateTime.parse(map['orderDate'] ?? DateTime.now().toString()),
      status: map['status'] ?? 'Unknown',
      total: map['total'] ?? 0.0,
    );
  }
}
