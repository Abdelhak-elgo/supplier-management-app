import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/database/database_helper.dart';
import 'package:supplier_management/features/clients/models/client.dart';
import 'package:supplier_management/features/clients/repository/client_repository.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';
import 'package:supplier_management/features/products/models/product.dart';
import 'package:supplier_management/features/products/repository/product_repository.dart';

class OrderRepository {
  final DatabaseHelper _databaseHelper;
  final ClientRepository? _clientRepository;
  final ProductRepository? _productRepository;

  OrderRepository(
    this._databaseHelper, {
    ClientRepository? clientRepository,
    ProductRepository? productRepository,
  })  : _clientRepository = clientRepository,
        _productRepository = productRepository;

  Future<List<Order>> getAllOrders() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT o.*, c.name as client_name
      FROM ${AppConstants.ordersTable} o
      JOIN ${AppConstants.clientsTable} c ON o.client_id = c.id
      ORDER BY o.order_date DESC
    ''');

    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  Future<List<Order>> getOrdersByStatus(String status) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT o.*, c.name as client_name
      FROM ${AppConstants.ordersTable} o
      JOIN ${AppConstants.clientsTable} c ON o.client_id = c.id
      WHERE o.status = ?
      ORDER BY o.order_date DESC
    ''', [status]);

    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  Future<List<Order>> getOrdersByClientId(int clientId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT o.*, c.name as client_name
      FROM ${AppConstants.ordersTable} o
      JOIN ${AppConstants.clientsTable} c ON o.client_id = c.id
      WHERE o.client_id = ?
      ORDER BY o.order_date DESC
    ''', [clientId]);

    return List.generate(maps.length, (i) {
      return Order.fromMap(maps[i]);
    });
  }

  Future<Order?> getOrderById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT o.*, c.name as client_name
      FROM ${AppConstants.ordersTable} o
      JOIN ${AppConstants.clientsTable} c ON o.client_id = c.id
      WHERE o.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return Order.fromMap(maps.first);
    }
    return null;
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT oi.*, p.name as product_name, p.description as product_description, p.category as product_category
      FROM ${AppConstants.orderItemsTable} oi
      JOIN ${AppConstants.productsTable} p ON oi.product_id = p.id
      WHERE oi.order_id = ?
    ''', [orderId]);

    return List.generate(maps.length, (i) {
      return OrderItem.fromMap(maps[i]);
    });
  }

  Future<Client?> getOrderClient(int orderId) async {
    if (_clientRepository == null) {
      throw Exception('Client repository is required to get order client');
    }

    final order = await getOrderById(orderId);
    if (order != null) {
      return _clientRepository!.getClientById(order.clientId);
    }
    return null;
  }

  Future<int> createOrder(Order order, List<OrderItem> items) async {
    final db = await _databaseHelper.database;
    int orderId;

    await db.transaction((txn) async {
      // Insert order
      orderId = await txn.insert(
        AppConstants.ordersTable,
        order.toMapForDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert order items with the new order ID
      for (var item in items) {
        final itemMap = item.copyWith(orderId: orderId).toMapForDb();
        await txn.insert(
          AppConstants.orderItemsTable,
          itemMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Update product quantity if product repository is available
        if (_productRepository != null) {
          final product = await _productRepository!.getProductById(item.productId);
          if (product != null) {
            final newQuantity = product.quantity - item.quantity;
            if (newQuantity >= 0) {
              await _productRepository!.updateProductQuantity(
                item.productId,
                newQuantity,
              );
            }
          }
        }
      }
    });

    return orderId;
  }

  Future<int> updateOrder(Order order, List<OrderItem> items) async {
    final db = await _databaseHelper.database;
    int result;

    await db.transaction((txn) async {
      // Update order
      result = await txn.update(
        AppConstants.ordersTable,
        order.copyWith(updatedAt: DateTime.now()).toMapForDb(),
        where: 'id = ?',
        whereArgs: [order.id],
      );

      // Get existing order items
      final List<Map<String, dynamic>> existingItems = await txn.query(
        AppConstants.orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [order.id],
      );

      // First, restore product quantities if product repository is available
      if (_productRepository != null) {
        for (var existingItemMap in existingItems) {
          final existingItem = OrderItem.fromMap(existingItemMap);
          final product = await _productRepository!.getProductById(existingItem.productId);
          if (product != null) {
            final restoredQuantity = product.quantity + existingItem.quantity;
            await _productRepository!.updateProductQuantity(
              existingItem.productId,
              restoredQuantity,
            );
          }
        }
      }

      // Delete all existing order items
      await txn.delete(
        AppConstants.orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [order.id],
      );

      // Insert new order items
      for (var item in items) {
        await txn.insert(
          AppConstants.orderItemsTable,
          item.toMapForDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Update product quantity again if product repository is available
        if (_productRepository != null) {
          final product = await _productRepository!.getProductById(item.productId);
          if (product != null) {
            final newQuantity = product.quantity - item.quantity;
            if (newQuantity >= 0) {
              await _productRepository!.updateProductQuantity(
                item.productId,
                newQuantity,
              );
            }
          }
        }
      }
    });

    return result;
  }

  Future<int> updateOrderStatus(int id, String status) async {
    final db = await _databaseHelper.database;
    return await db.update(
      AppConstants.ordersTable,
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteOrder(int id) async {
    final db = await _databaseHelper.database;
    int result;

    await db.transaction((txn) async {
      // Get order items to restore product quantities
      if (_productRepository != null) {
        final List<Map<String, dynamic>> items = await txn.query(
          AppConstants.orderItemsTable,
          where: 'order_id = ?',
          whereArgs: [id],
        );

        for (var itemMap in items) {
          final item = OrderItem.fromMap(itemMap);
          final product = await _productRepository!.getProductById(item.productId);
          if (product != null) {
            final restoredQuantity = product.quantity + item.quantity;
            await _productRepository!.updateProductQuantity(
              item.productId,
              restoredQuantity,
            );
          }
        }
      }

      // Delete order items
      await txn.delete(
        AppConstants.orderItemsTable,
        where: 'order_id = ?',
        whereArgs: [id],
      );

      // Delete order
      result = await txn.delete(
        AppConstants.ordersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getOrderSummaryByStatus() async {
    final db = await _databaseHelper.database;
    return await db.rawQuery('''
      SELECT status, COUNT(*) as count, SUM(total) as total
      FROM ${AppConstants.ordersTable}
      GROUP BY status
    ''');
  }

  Future<double> getTotalSales({DateTime? startDate, DateTime? endDate}) async {
    final db = await _databaseHelper.database;
    String query = '''
      SELECT SUM(total) as total
      FROM ${AppConstants.ordersTable}
      WHERE status = 'Completed'
    ''';

    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      query += ' AND order_date BETWEEN ? AND ?';
      args.add(startDate.toIso8601String());
      args.add(endDate.toIso8601String());
    } else if (startDate != null) {
      query += ' AND order_date >= ?';
      args.add(startDate.toIso8601String());
    } else if (endDate != null) {
      query += ' AND order_date <= ?';
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(query, args);
    return result.first['total'] as double? ?? 0.0;
  }
}
