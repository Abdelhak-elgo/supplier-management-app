import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/database/database_helper.dart';
import 'package:supplier_management/features/products/models/product.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper;

  ProductRepository(this._databaseHelper);

  Future<List<Product>> getAllProducts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.productsTable);

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.productsTable,
      where: 'category = ?',
      whereArgs: [category],
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.productsTable,
      where: 'name LIKE ? OR description LIKE ? OR category LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.productsTable,
      where: 'quantity <= min_stock_level',
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<Product?> getProductById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.productsTable,
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertProduct(Product product) async {
    final db = await _databaseHelper.database;
    final productMap = product.toMapForDb();
    
    // Ensure created_at is set
    productMap['created_at'] = DateTime.now().toIso8601String();
    
    return await db.insert(
      AppConstants.productsTable,
      productMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateProduct(Product product) async {
    final db = await _databaseHelper.database;
    final productMap = product.toMapForDb();
    
    // Set updated_at timestamp
    productMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.update(
      AppConstants.productsTable,
      productMap,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      AppConstants.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProductQuantity(int id, int newQuantity) async {
    final db = await _databaseHelper.database;
    return await db.update(
      AppConstants.productsTable,
      {
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM ${AppConstants.productsTable} ORDER BY category',
    );

    return List.generate(maps.length, (i) {
      return maps[i]['category'] as String;
    });
  }

  Future<bool> checkIfBarcodeExists(String barcode, {int? excludeProductId}) async {
    final db = await _databaseHelper.database;
    String query = 'SELECT COUNT(*) as count FROM ${AppConstants.productsTable} WHERE barcode = ?';
    List<dynamic> args = [barcode];
    
    if (excludeProductId != null) {
      query += ' AND id != ?';
      args.add(excludeProductId);
    }
    
    final result = await db.rawQuery(query, args);
    return (result.first['count'] as int) > 0;
  }
}
