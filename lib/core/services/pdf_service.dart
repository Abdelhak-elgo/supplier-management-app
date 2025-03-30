import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supplier_management/features/clients/models/client.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';
import 'package:supplier_management/features/invoices/models/invoice.dart';
import 'package:supplier_management/core/utils/date_formatter.dart';

class PdfService {
  Future<String> generateInvoicePdf(Invoice invoice, Order order, Client client, List<OrderItem> orderItems) async {
    final pdf = pw.Document();
    
    // Load font
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    
    // Add page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(invoice, ttf),
          _buildInvoiceInfo(invoice, order, ttf),
          _buildClientInfo(client, ttf),
          _buildItemsTable(orderItems, ttf),
          pw.SizedBox(height: 20),
          _buildTotal(order, ttf),
          pw.SizedBox(height: 20),
          _buildFooter(ttf),
        ],
      ),
    );
    
    // Save the PDF file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/invoices/INV-${invoice.invoiceNumber}.pdf';
    
    // Ensure the directory exists
    final dir = Directory('${directory.path}/invoices');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // Write PDF to file
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return filePath;
  }
  
  Future<void> printInvoice(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Printing.layoutPdf(
        onLayout: (_) => file.readAsBytes(),
      );
    }
  }
  
  Future<void> sharePdf(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Printing.sharePdf(bytes: await file.readAsBytes(), filename: 'invoice.pdf');
    }
  }
  
  pw.Widget _buildHeader(Invoice invoice, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                font: font,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Invoice #: ${invoice.invoiceNumber}',
              style: pw.TextStyle(font: font, fontSize: 14),
            ),
          ],
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
      ],
    );
  }
  
  pw.Widget _buildInvoiceInfo(Invoice invoice, Order order, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Issue Date: ${DateFormatter.formatDate(invoice.issueDate)}',
                style: pw.TextStyle(font: font)),
            pw.Text('Due Date: ${DateFormatter.formatDate(invoice.dueDate)}',
                style: pw.TextStyle(font: font)),
            pw.Text('Order Date: ${DateFormatter.formatDate(order.orderDate)}',
                style: pw.TextStyle(font: font)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Status: ${invoice.paymentStatus}',
                style: pw.TextStyle(
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                  color: invoice.paymentStatus == 'Paid'
                      ? PdfColors.green
                      : invoice.paymentStatus == 'Overdue'
                          ? PdfColors.red
                          : PdfColors.orange,
                )),
            if (invoice.paymentDate != null)
              pw.Text('Payment Date: ${DateFormatter.formatDate(invoice.paymentDate!)}',
                  style: pw.TextStyle(font: font)),
          ],
        ),
      ],
    );
  }
  
  pw.Widget _buildClientInfo(Client client, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 30, bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To:',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.SizedBox(height: 5),
              pw.Text(client.name, style: pw.TextStyle(font: font)),
              if (client.phone.isNotEmpty)
                pw.Text('Phone: ${client.phone}', style: pw.TextStyle(font: font)),
              if (client.city.isNotEmpty)
                pw.Text('City: ${client.city}', style: pw.TextStyle(font: font)),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildItemsTable(List<OrderItem> items, pw.Font font) {
    final tableHeaders = [
      'No.',
      'Product',
      'Quantity',
      'Unit Price',
      'Total',
    ];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Table header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: tableHeaders.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              header,
              style: pw.TextStyle(
                font: font,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: header == 'Product' ? pw.TextAlign.left : pw.TextAlign.center,
            ),
          )).toList(),
        ),
        // Table rows
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${index + 1}', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(item.productName ?? 'Product', style: pw.TextStyle(font: font)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${item.quantity}', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('\$${item.pricePerUnit.toStringAsFixed(2)}', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('\$${item.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(font: font), textAlign: pw.TextAlign.center),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  pw.Widget _buildTotal(Order order, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 150,
                child: pw.Text(
                  'Subtotal:',
                  style: pw.TextStyle(font: font),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Container(
                width: 100,
                child: pw.Text(
                  '\$${order.subtotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 150,
                child: pw.Text(
                  'Total:',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Container(
                width: 100,
                child: pw.Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildFooter(pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            font: font,
            fontStyle: pw.FontStyle.italic,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
