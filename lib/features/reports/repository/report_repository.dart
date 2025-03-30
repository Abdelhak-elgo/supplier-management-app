import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/database/database_helper.dart';
import 'package:supplier_management/features/reports/models/sales_report.dart';

class ReportRepository {
  final DatabaseHelper _databaseHelper;

  ReportRepository(this._databaseHelper);

  Future<SalesReport> generateSalesReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _databaseHelper.database;
    
    // Format dates for SQLite
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    // Get total sales and order counts
    final salesQuery = '''
      SELECT 
        SUM(CASE WHEN status = 'Completed' THEN total ELSE 0 END) as total_sales,
        COUNT(*) as total_orders,
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) as cancelled_orders
      FROM ${AppConstants.ordersTable}
      WHERE order_date BETWEEN ? AND ?
    ''';
    
    final salesResult = await db.rawQuery(salesQuery, [startDateStr, endDateStr]);
    final totalSales = salesResult.first['total_sales'] != null 
        ? (salesResult.first['total_sales'] as num).toDouble() 
        : 0.0;
    final totalOrders = salesResult.first['total_orders'] as int? ?? 0;
    final cancelledOrders = salesResult.first['cancelled_orders'] as int? ?? 0;
    
    // Get top selling products
    final topProductsQuery = '''
      SELECT 
        oi.product_id,
        p.name as product_name,
        SUM(oi.quantity) as quantity,
        SUM(oi.subtotal) as revenue
      FROM ${AppConstants.orderItemsTable} oi
      JOIN ${AppConstants.ordersTable} o ON oi.order_id = o.id
      JOIN ${AppConstants.productsTable} p ON oi.product_id = p.id
      WHERE o.order_date BETWEEN ? AND ? AND o.status != 'Cancelled'
      GROUP BY oi.product_id
      ORDER BY revenue DESC
      LIMIT 5
    ''';
    
    final topProductsResult = await db.rawQuery(topProductsQuery, [startDateStr, endDateStr]);
    final topProducts = topProductsResult
        .map<ProductSales>((map) => ProductSales.fromMap(map))
        .toList();
    
    // Get top clients
    final topClientsQuery = '''
      SELECT 
        o.client_id,
        c.name as client_name,
        COUNT(o.id) as order_count,
        SUM(o.total) as total_spent
      FROM ${AppConstants.ordersTable} o
      JOIN ${AppConstants.clientsTable} c ON o.client_id = c.id
      WHERE o.order_date BETWEEN ? AND ? AND o.status != 'Cancelled'
      GROUP BY o.client_id
      ORDER BY total_spent DESC
      LIMIT 5
    ''';
    
    final topClientsResult = await db.rawQuery(topClientsQuery, [startDateStr, endDateStr]);
    final topClients = topClientsResult
        .map<ClientSales>((map) => ClientSales.fromMap(map))
        .toList();
    
    // Get daily sales
    final dailySalesQuery = '''
      SELECT 
        date(o.order_date) as date,
        SUM(o.total) as sales,
        COUNT(o.id) as order_count
      FROM ${AppConstants.ordersTable} o
      WHERE o.order_date BETWEEN ? AND ? AND o.status != 'Cancelled'
      GROUP BY date(o.order_date)
      ORDER BY date(o.order_date)
    ''';
    
    final dailySalesResult = await db.rawQuery(dailySalesQuery, [startDateStr, endDateStr]);
    final dailySales = dailySalesResult
        .map<DailySales>((map) => DailySales.fromMap(map))
        .toList();
    
    return SalesReport(
      startDate: startDate,
      endDate: endDate,
      totalSales: totalSales,
      totalOrders: totalOrders,
      cancelledOrders: cancelledOrders,
      topProducts: topProducts,
      topClients: topClients,
      dailySales: dailySales,
    );
  }

  Future<Map<String, dynamic>> getInventoryReport() async {
    final db = await _databaseHelper.database;
    
    // Get inventory summary
    final inventorySummaryQuery = '''
      SELECT 
        COUNT(*) as total_products,
        SUM(quantity) as total_stock,
        SUM(CASE WHEN quantity <= min_stock_level THEN 1 ELSE 0 END) as low_stock_count,
        SUM(price * quantity) as inventory_value
      FROM ${AppConstants.productsTable}
    ''';
    
    final inventorySummaryResult = await db.rawQuery(inventorySummaryQuery);
    
    // Get low stock products
    final lowStockQuery = '''
      SELECT id, name, category, quantity, min_stock_level, price
      FROM ${AppConstants.productsTable}
      WHERE quantity <= min_stock_level
      ORDER BY (min_stock_level - quantity) DESC
    ''';
    
    final lowStockResult = await db.rawQuery(lowStockQuery);
    
    // Get stock value by category
    final categoryValueQuery = '''
      SELECT 
        category,
        SUM(quantity) as total_quantity,
        SUM(price * quantity) as total_value
      FROM ${AppConstants.productsTable}
      GROUP BY category
      ORDER BY total_value DESC
    ''';
    
    final categoryValueResult = await db.rawQuery(categoryValueQuery);
    
    return {
      'summary': inventorySummaryResult.first,
      'lowStock': lowStockResult,
      'categoryValue': categoryValueResult,
    };
  }

  Future<Map<String, dynamic>> getClientReport() async {
    final db = await _databaseHelper.database;
    
    // Get client summary
    final clientSummaryQuery = '''
      SELECT 
        COUNT(*) as total_clients,
        SUM(CASE WHEN type = 'VIP' THEN 1 ELSE 0 END) as vip_clients,
        SUM(CASE WHEN type = 'Regular' THEN 1 ELSE 0 END) as regular_clients,
        SUM(CASE WHEN type = 'New' THEN 1 ELSE 0 END) as new_clients
      FROM ${AppConstants.clientsTable}
    ''';
    
    final clientSummaryResult = await db.rawQuery(clientSummaryQuery);
    
    // Get top clients by order count
    final topClientsByOrdersQuery = '''
      SELECT 
        c.id, c.name, c.type,
        COUNT(o.id) as order_count
      FROM ${AppConstants.clientsTable} c
      LEFT JOIN ${AppConstants.ordersTable} o ON c.id = o.client_id
      GROUP BY c.id
      ORDER BY order_count DESC
      LIMIT 10
    ''';
    
    final topClientsByOrdersResult = await db.rawQuery(topClientsByOrdersQuery);
    
    // Get clients with no orders
    final inactiveClientsQuery = '''
      SELECT c.id, c.name, c.type, c.created_at
      FROM ${AppConstants.clientsTable} c
      LEFT JOIN ${AppConstants.ordersTable} o ON c.id = o.client_id
      WHERE o.id IS NULL
    ''';
    
    final inactiveClientsResult = await db.rawQuery(inactiveClientsQuery);
    
    return {
      'summary': clientSummaryResult.first,
      'topClients': topClientsByOrdersResult,
      'inactiveClients': inactiveClientsResult,
    };
  }
}
