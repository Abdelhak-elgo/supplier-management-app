import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/pdf_service.dart';
import '../../clients/models/client.dart';
import '../models/invoice.dart';
import '../../orders/models/order.dart';
import '../../orders/models/order_item.dart';
import '../../orders/repository/order_repository.dart';

class InvoiceRepository {
  final DatabaseHelper _databaseHelper;
  final OrderRepository _orderRepository;
  final PdfService _pdfService = PdfService();

  InvoiceRepository(this._databaseHelper, this._orderRepository);

  Future<List<Invoice>> getAllInvoices() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT i.*, o.total as order_total, c.name as client_name
      FROM ${AppConstants.invoicesTable} i
      JOIN ${AppConstants.ordersTable} o ON i.order_id = o.id
      JOIN ${AppConstants.clientsTable} c ON o.client_id = c.id
      ORDER BY i.issue_date DESC
    ''');

    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  Future<List<Invoice>> getInvoicesByPaymentStatus(String status) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT i.*, o.total as order_total, c.name as client_name
      FROM ${AppConstants.invoicesTable} i
      JOIN ${AppConstants.ordersTable} o ON i.order_id = o.id
      JOIN ${AppConstants.clientsTable} c ON o.client_id = c.id
      WHERE i.payment_status = ?
      ORDER BY i.issue_date DESC
    ''', [status]);

    return List.generate(maps.length, (i) {
      return Invoice.fromMap(maps[i]);
    });
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT i.*, o.total as order_total, c.name as client_name
      FROM ${AppConstants.invoicesTable} i
      JOIN ${AppConstants.ordersTable} o ON i.order_id = o.id
      JOIN ${AppConstants.clientsTable} c ON o.client_id = c.id
      WHERE i.id = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return Invoice.fromMap(maps.first);
    }
    return null;
  }

  Future<Invoice?> getInvoiceByOrderId(int orderId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.invoicesTable,
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    if (maps.isNotEmpty) {
      return Invoice.fromMap(maps.first);
    }
    return null;
  }

  Future<String> _generateInvoiceNumber() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.invoicesTable}');
    final count = result.first['count'] as int? ?? 0;
    final year = DateTime.now().year;
    return 'INV-$year-${(count + 1).toString().padLeft(5, '0')}';
  }

  Future<Invoice> generateInvoice(int orderId) async {
    // Check if invoice already exists for this order
    final existingInvoice = await getInvoiceByOrderId(orderId);
    if (existingInvoice != null) {
      return existingInvoice;
    }

    // Get order details
    final order = await _orderRepository.getOrderById(orderId);
    if (order == null) {
      throw Exception('Order not found');
    }

    // Get client details
    final client = await _orderRepository.getOrderClient(orderId);
    if (client == null) {
      throw Exception('Client not found');
    }

    // Get order items
    final orderItems = await _orderRepository.getOrderItems(orderId);

    // Generate PDF
    final invoiceNumber = await _generateInvoiceNumber();
    final issueDate = DateTime.now();
    final dueDate = issueDate.add(const Duration(days: 30));

    // Create invoice
    final invoice = Invoice(
      orderId: orderId,
      invoiceNumber: invoiceNumber,
      issueDate: issueDate,
      dueDate: dueDate,
      paymentStatus: AppConstants.paymentStatusPending,
      clientName: client.name,
      orderTotal: order.total,
    );

    // Generate PDF
    final pdfPath = await _pdfService.generateInvoicePdf(
      invoice,
      order,
      client,
      orderItems,
    );

    // Save invoice with PDF path
    final invoiceWithPdf = invoice.copyWith(pdfPath: pdfPath);
    final id = await insertInvoice(invoiceWithPdf);

    return invoiceWithPdf.copyWith(id: id);
  }

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      AppConstants.invoicesTable,
      invoice.toMapForDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateInvoice(Invoice invoice) async {
    final db = await _databaseHelper.database;
    return await db.update(
      AppConstants.invoicesTable,
      invoice.toMapForDb(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<int> updatePaymentStatus(int id, String status, {DateTime? paymentDate}) async {
    final db = await _databaseHelper.database;
    final map = {
      'payment_status': status,
    };
    
    if (status == AppConstants.paymentStatusPaid && paymentDate != null) {
      map['payment_date'] = paymentDate.toIso8601String();
    }
    
    return await db.update(
      AppConstants.invoicesTable,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> shareInvoice(String filePath) async {
    await _pdfService.sharePdf(filePath);
  }

  Future<void> printInvoice(String filePath) async {
    await _pdfService.printInvoice(filePath);
  }

  Future<Map<String, dynamic>> getInvoiceDetails(int id) async {
    final invoice = await getInvoiceById(id);
    if (invoice == null) {
      throw Exception('Invoice not found');
    }

    final order = await _orderRepository.getOrderById(invoice.orderId);
    if (order == null) {
      throw Exception('Order not found');
    }

    final client = await _orderRepository.getOrderClient(invoice.orderId);
    final orderItems = await _orderRepository.getOrderItems(invoice.orderId);

    return {
      'invoice': invoice,
      'order': order,
      'client': client,
      'orderItems': orderItems,
    };
  }
}
