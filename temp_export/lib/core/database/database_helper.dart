import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supplier_management/features/products/models/product.dart';
import 'package:supplier_management/features/clients/models/client.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';
import 'package:supplier_management/features/invoices/models/invoice.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initializeDatabase();
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'supplier_management.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        price REAL NOT NULL,
        quantity INTEGER DEFAULT 0,
        min_stock_level INTEGER DEFAULT 5,
        barcode TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    // Clients Table
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        city TEXT,
        notes TEXT,
        type TEXT DEFAULT 'Regular',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Orders Table
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER REFERENCES clients(id),
        order_date TEXT DEFAULT CURRENT_TIMESTAMP,
        status TEXT CHECK(status IN ('New', 'Processing', 'Completed', 'Cancelled')),
        subtotal REAL,
        total REAL,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    // Order Items (Junction Table)
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER REFERENCES orders(id),
        product_id INTEGER REFERENCES products(id),
        quantity INTEGER NOT NULL,
        price_per_unit REAL NOT NULL,
        subtotal REAL
      )
    ''');

    // Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER REFERENCES orders(id),
        invoice_number TEXT UNIQUE,
        issue_date TEXT,
        due_date TEXT,
        payment_status TEXT DEFAULT 'Pending',
        payment_date TEXT,
        pdf_path TEXT
      )
    ''');

    // Create indices for faster queries
    await db.execute('CREATE INDEX idx_product_name ON products(name)');
    await db.execute('CREATE INDEX idx_product_category ON products(category)');
    await db.execute('CREATE INDEX idx_client_name ON clients(name)');
    await db.execute('CREATE INDEX idx_order_client ON orders(client_id)');
    await db.execute('CREATE INDEX idx_order_status ON orders(status)');
    await db.execute('CREATE INDEX idx_order_date ON orders(order_date)');
    await db.execute('CREATE INDEX idx_order_item_order ON order_items(order_id)');
    await db.execute('CREATE INDEX idx_order_item_product ON order_items(product_id)');
    await db.execute('CREATE INDEX idx_invoice_order ON invoices(order_id)');
    await db.execute('CREATE INDEX idx_invoice_status ON invoices(payment_status)');
  }

  // Generic database operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, data, where: whereClause, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: whereClause, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(String table, {
    String? whereClause,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  Future<void> batch(Function(Batch batch) action) async {
    final db = await database;
    final batch = db.batch();
    action(batch);
    await batch.commit();
  }

  Future<void> transaction(Function(Transaction txn) action) async {
    final db = await database;
    await db.transaction((txn) async {
      await action(txn);
    });
  }
}
