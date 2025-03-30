import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/utils/date_formatter.dart';
import 'package:supplier_management/core/widgets/confirmation_dialog.dart';
import 'package:supplier_management/core/widgets/error_widget.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/features/invoices/bloc/invoice_bloc.dart';
import 'package:supplier_management/features/orders/bloc/order_bloc.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';
import 'package:supplier_management/features/orders/widgets/order_item_card.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({Key? key}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  int? _orderId;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_orderId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is int) {
        _orderId = args;
        _loadOrderDetails();
      }
    }
  }
  
  void _loadOrderDetails() {
    if (_orderId != null) {
      context.read<OrderBloc>().add(LoadOrderById(_orderId!));
    }
  }
  
  void _updateOrderStatus(String newStatus) {
    if (_orderId != null) {
      context.read<OrderBloc>().add(UpdateOrderStatus(_orderId!, newStatus));
    }
  }
  
  void _confirmDeleteOrder(Order order) {
    ConfirmationDialog.showDeleteConfirmation(
      context: context,
      itemType: 'Order',
      itemName: 'Order #${order.id}',
      onConfirm: () {
        context.read<OrderBloc>().add(DeleteOrder(order.id!));
      },
    );
  }
  
  void _createInvoice(Order order) {
    if (order.id != null) {
      context.read<InvoiceBloc>().add(GenerateInvoice(order.id!));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state is OrderDetails) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.pushNamed(
                        context,
                        '/orders/edit',
                        arguments: state.order,
                      ).then((_) => _loadOrderDetails());
                    } else if (value == 'delete') {
                      _confirmDeleteOrder(state.order);
                    } else if (value == 'invoice') {
                      _createInvoice(state.order);
                    } else if (value.startsWith('status_')) {
                      _updateOrderStatus(value.substring(7));
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit Order'),
                    ),
                    PopupMenuItem<String>(
                      value: 'invoice',
                      enabled: state.order.status != 'Cancelled',
                      child: const Text('Generate Invoice'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'status_New',
                      child: Text('Mark as New'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'status_Processing',
                      child: Text('Mark as Processing'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'status_Completed',
                      child: Text('Mark as Completed'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'status_Cancelled',
                      child: Text('Mark as Cancelled'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Order'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
                
                if (state.message.contains('deleted')) {
                  Navigator.pop(context);
                } else {
                  _loadOrderDetails();
                }
              } else if (state is OrderError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
          BlocListener<InvoiceBloc, InvoiceState>(
            listener: (context, state) {
              if (state is InvoiceGenerated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice generated successfully')),
                );
                Navigator.pushNamed(
                  context,
                  '/invoices/detail',
                  arguments: state.invoice.id,
                );
              } else if (state is InvoiceError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const LoadingWidget();
            } else if (state is OrderDetails) {
              return _buildOrderDetails(state.order, state.items, state.client);
            } else if (state is OrderError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: _loadOrderDetails,
              );
            }
            
            return const LoadingWidget();
          },
        ),
      ),
      floatingActionButton: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderDetails && state.order.status != 'Cancelled') {
            return FloatingActionButton.extended(
              onPressed: () => _createInvoice(state.order),
              icon: const Icon(Icons.receipt),
              label: const Text('Generate Invoice'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
  
  Widget _buildOrderDetails(Order order, List<OrderItem> items, client) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadOrderDetails();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderStatusCard(order),
            const SizedBox(height: 16),
            _buildClientInfoCard(order, client),
            const SizedBox(height: 16),
            _buildOrderItemsCard(items),
            const SizedBox(height: 16),
            if (order.notes.isNotEmpty) _buildNotesCard(order.notes),
            const SizedBox(height: 16),
            _buildTotalCard(order),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderStatusCard(Order order) {
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
                  'Order #${order.id}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Date:'),
                Text(
                  DateFormatter.formatDate(order.orderDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Created:'),
                Text(
                  DateFormatter.formatDateTime(order.createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (order.updatedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Last Updated:'),
                  Text(
                    DateFormatter.formatDateTime(order.updatedAt!),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
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
      case 'New':
        color = Colors.blue;
        break;
      case 'Processing':
        color = Colors.orange;
        break;
      case 'Completed':
        color = Colors.green;
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
  
  Widget _buildClientInfoCard(Order order, client) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            if (client != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(client.name[0]),
                ),
                title: Text(client.name),
                subtitle: Text(client.phone),
                trailing: IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/clients/detail',
                      arguments: client.id,
                    );
                  },
                ),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(order.clientName ?? 'Unknown Client'),
                subtitle: const Text('Client details not available'),
              ),
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
              'Products',
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
                return OrderItemCard(
                  orderItem: items[index],
                  isReadOnly: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotesCard(String notes) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            Text(notes),
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
                  'Total:',
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
}
