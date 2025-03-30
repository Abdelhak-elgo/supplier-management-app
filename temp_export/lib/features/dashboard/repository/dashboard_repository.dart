import 'package:supplier_management/core/database/database_helper.dart';
import 'package:supplier_management/features/dashboard/models/dashboard_stats.dart';

class DashboardRepository {
  final DatabaseHelper _databaseHelper;

  DashboardRepository(this._databaseHelper);

  Future<DashboardStats> getDashboardStats() async {
    final db = await _databaseHelper.database;

    // Get product stats
    final productStats = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalProducts,
        SUM(CASE WHEN quantity <= min_stock_level THEN 1 ELSE 0 END) as lowStockProducts
      FROM products
    ''');

    // Get order stats
    final orderStats = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN status = 'Completed' THEN total ELSE 0 END) as totalSales,
        SUM(CASE WHEN status IN ('New', 'Processing') THEN 1 ELSE 0 END) as pendingOrders,
        SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) as completedOrders
      FROM orders
    ''');

    // Get recent orders
    final recentOrders = await db.rawQuery('''
      SELECT 
        o.id, 
        c.name as clientName, 
        o.order_date as orderDate, 
        o.status, 
        o.total 
      FROM orders o
      JOIN clients c ON o.client_id = c.id
      ORDER BY o.order_date DESC
      LIMIT 5
    ''');

    final stats = {
      'totalProducts': productStats.first['totalProducts'] as int? ?? 0,
      'lowStockProducts': productStats.first['lowStockProducts'] as int? ?? 0,
      'totalSales': orderStats.first['totalSales'] as double? ?? 0.0,
      'pendingOrders': orderStats.first['pendingOrders'] as int? ?? 0,
      'completedOrders': orderStats.first['completedOrders'] as int? ?? 0,
    };

    return DashboardStats.fromMap(stats, recentOrders);
  }
}
