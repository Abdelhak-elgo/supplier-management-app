import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/database/database_helper.dart';
import 'package:supplier_management/features/clients/models/client.dart';

class ClientRepository {
  final DatabaseHelper _databaseHelper;

  ClientRepository(this._databaseHelper);

  Future<List<Client>> getAllClients() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.clientsTable,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Client.fromMap(maps[i]);
    });
  }

  Future<List<Client>> searchClients(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.clientsTable,
      where: 'name LIKE ? OR phone LIKE ? OR city LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Client.fromMap(maps[i]);
    });
  }

  Future<List<Client>> getClientsByType(String type) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.clientsTable,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Client.fromMap(maps[i]);
    });
  }

  Future<Client?> getClientById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.clientsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Client.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertClient(Client client) async {
    final db = await _databaseHelper.database;
    final clientMap = client.toMapForDb();
    
    // Ensure created_at is set
    clientMap['created_at'] = DateTime.now().toIso8601String();
    
    return await db.insert(
      AppConstants.clientsTable,
      clientMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateClient(Client client) async {
    final db = await _databaseHelper.database;
    return await db.update(
      AppConstants.clientsTable,
      client.toMapForDb(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      AppConstants.clientsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getClientStats(int clientId) async {
    final db = await _databaseHelper.database;
    
    // Get total orders
    final orderCountResult = await db.rawQuery('''
      SELECT COUNT(*) as orderCount
      FROM ${AppConstants.ordersTable}
      WHERE client_id = ?
    ''', [clientId]);
    
    // Get total spent
    final totalSpentResult = await db.rawQuery('''
      SELECT SUM(total) as totalSpent
      FROM ${AppConstants.ordersTable}
      WHERE client_id = ? AND status = 'Completed'
    ''', [clientId]);
    
    // Get last order date
    final lastOrderResult = await db.rawQuery('''
      SELECT order_date
      FROM ${AppConstants.ordersTable}
      WHERE client_id = ?
      ORDER BY order_date DESC
      LIMIT 1
    ''', [clientId]);
    
    return {
      'orderCount': orderCountResult.first['orderCount'] as int? ?? 0,
      'totalSpent': totalSpentResult.first['totalSpent'] as double? ?? 0.0,
      'lastOrderDate': lastOrderResult.isNotEmpty ? lastOrderResult.first['order_date'] as String? : null,
    };
  }
}
