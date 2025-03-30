import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/utils/date_formatter.dart';
import 'package:supplier_management/core/widgets/error_widget.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/features/invoices/bloc/invoice_bloc.dart';
import 'package:supplier_management/features/invoices/models/invoice.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({Key? key}) : super(key: key);

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  int? _invoiceId;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_invoiceId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is int) {
        _invoiceId = args;
        _loadInvoiceDetails();
      }
    }
  }
  
  void _loadInvoiceDetails() {
    if (_invoiceId != null) {
      context.read<InvoiceBloc>().add(LoadInvoiceById(_invoiceId!));
    }
  }
  
  void _shareInvoice(String filePath) {
    context.read<InvoiceBloc>().add(ShareInvoice(filePath));
  }
  
  void _printInvoice(String filePath) {
    context.read<InvoiceBloc>().add(PrintInvoice(filePath));
  }
  
  void _updatePaymentStatus(int invoiceId, String status) {
    context.read<InvoiceBloc>().add(
      UpdateInvoicePaymentStatus(
        invoiceId,
        status,
        paymentDate: status == AppConstants.paymentStatusPaid
            ? DateTime.now()
            : null,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          BlocBuilder<InvoiceBloc, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceDetails && state.invoice.pdfPath != null) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'share') {
                      _shareInvoice(state.invoice.pdfPath!);
                    } else if (value == 'print') {
                      _printInvoice(state.invoice.pdfPath!);
                    } else if (value.startsWith('status_')) {
                      _updatePaymentStatus(
                        state.invoice.id!,
                        value.substring(7),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Text('Share Invoice'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'print',
                      child: Text('Print Invoice'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'status_Pending',
                      child: Text('Mark as Pending'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'status_Paid',
                      child: Text('Mark as Paid'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'status_Overdue',
                      child: Text('Mark as Overdue'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is InvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is InvoicesLoading) {
            return const LoadingWidget();
          } else if (state is InvoiceDetails) {
            return _buildInvoiceDetails(
              state.invoice,
              state.order,
              state.client,
              state.orderItems,
            );
          } else if (state is InvoiceError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: _loadInvoiceDetails,
            );
          }
          
          return const LoadingWidget();
        },
      ),
      floatingActionButton: BlocBuilder<InvoiceBloc, InvoiceState>(
        builder: (context, state) {
          if (state is InvoiceDetails && state.invoice.pdfPath != null) {
            return FloatingActionButton.extended(
              onPressed: () => _shareInvoice(state.invoice.pdfPath!),
              icon: const Icon(Icons.share),
              label: const Text('Share Invoice'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
  
  Widget _buildInvoiceDetails(
    Invoice invoice,
    Order order,
    dynamic client,
    List<dynamic> orderItems,
  ) {
    final List<OrderItem> items = List.from(orderItems);
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadInvoiceDetails();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInvoiceStatusCard(invoice),
            const SizedBox(height: 16),
            _buildClientInfoCard(client),
            const SizedBox(height: 16),
            _buildOrderItemsCard(items),
            const SizedBox(height: 16),
            _buildTotalCard(order),
            const SizedBox(height: 24),
            if (invoice.pdfPath != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _openPdfPreview(invoice.pdfPath!),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View PDF Invoice'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInvoiceStatusCard(Invoice invoice) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice #${invoice.invoiceNumber}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(invoice.paymentStatus),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Issue Date:'),
                Text(
                  DateFormatter.formatDate(invoice.issueDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Due Date:'),
                Text(
                  DateFormatter.formatDate(invoice.dueDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (invoice.paymentDate != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Date:'),
                  Text(
                    DateFormatter.formatDate(invoice.paymentDate!),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            if (invoice.paymentStatus == AppConstants.paymentStatusOverdue) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This invoice is overdue!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Paid':
        color = Colors.green;
        break;
      case 'Overdue':
        color = Colors.red;
        break;
      case 'Cancelled':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildClientInfoCard(dynamic client) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill To',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            if (client != null) ...[
              Text(
                client.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (client.phone.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(client.phone),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (client.city.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_city, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(client.city),
                  ],
                ),
              ],
            ] else ...[
              const Text('Client information not available'),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderItemsCard(List<OrderItem> items) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.productName ?? 'Product #${item.productId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${item.quantity} × \$${item.pricePerUnit.toStringAsFixed(2)}'),
                  trailing: Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTotalCard(Order order) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(
                  '\$${order.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Due:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _openPdfPreview(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice PDF file not found')),
      );
      return;
    }
    
    // Navigate to a PDF viewer screen or use a plugin
    // For this simplified version, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF available at: $filePath'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => _shareInvoice(filePath),
        ),
      ),
    );
  }
}
