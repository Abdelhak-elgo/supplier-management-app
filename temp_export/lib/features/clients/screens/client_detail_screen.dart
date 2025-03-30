import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supplier_management/core/utils/date_formatter.dart';
import 'package:supplier_management/core/widgets/confirmation_dialog.dart';
import 'package:supplier_management/core/widgets/empty_state_widget.dart';
import 'package:supplier_management/core/widgets/error_widget.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/features/clients/bloc/client_bloc.dart';
import 'package:supplier_management/features/clients/models/client.dart';
import 'package:supplier_management/features/orders/bloc/order_bloc.dart';
import 'package:supplier_management/features/orders/models/order.dart' as order_model;

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({Key? key}) : super(key: key);

  @override
  _ClientDetailScreenState createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  int? _clientId;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_clientId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is int) {
        _clientId = args;
        _loadClientWithStats();
      }
    }
  }
  
  void _loadClientWithStats() {
    if (_clientId != null) {
      context.read<ClientBloc>().add(LoadClientStats(_clientId!));
      context.read<OrderBloc>().add(LoadOrdersByClientId(_clientId!));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        actions: [
          BlocBuilder<ClientBloc, ClientState>(
            builder: (context, state) {
              if (state is ClientWithStats) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editClient(context, state.client),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmDelete(context, state.client),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ClientBloc, ClientState>(
        listener: (context, state) {
          if (state is ClientOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            
            if (state.message.contains('deleted')) {
              Navigator.pop(context);
            }
          } else if (state is ClientError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ClientsLoading) {
            return const LoadingWidget();
          } else if (state is ClientWithStats) {
            return _buildClientDetails(context, state.client, state.stats);
          } else if (state is ClientError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: _loadClientWithStats,
            );
          }
          
          return const LoadingWidget();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/orders/add',
            arguments: _clientId,
          );
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('New Order'),
      ),
    );
  }
  
  Widget _buildClientDetails(BuildContext context, Client client, Map<String, dynamic> stats) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadClientWithStats();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientInfoCard(context, client),
            const SizedBox(height: 16),
            _buildStatsGrid(context, stats),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Recent Orders'),
            const SizedBox(height: 8),
            _buildClientOrders(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildClientInfoCard(BuildContext context, Client client) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              client.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getClientTypeColor(client.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getClientTypeColor(client.type).withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              client.type,
                              style: TextStyle(
                                color: _getClientTypeColor(client.type),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Since ${DateFormat('MMM yyyy').format(client.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (client.phone.isNotEmpty)
              _buildContactDetail(context, Icons.phone, 'Phone', client.phone),
            if (client.city.isNotEmpty)
              _buildContactDetail(context, Icons.location_city, 'City', client.city),
            if (client.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                client.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactDetail(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    final orderCount = stats['orderCount'] as int;
    final totalSpent = stats['totalSpent'] as double;
    final lastOrderDate = stats['lastOrderDate'] != null
        ? DateFormatter.parseDate(stats['lastOrderDate'] as String)
        : null;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Orders',
                    orderCount.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Spent',
                    '\$${totalSpent.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            lastOrderDate != null
                ? _buildLastOrderInfo(context, lastOrderDate)
                : const Center(
                    child: Text('No orders yet'),
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLastOrderInfo(BuildContext context, DateTime lastOrderDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Order',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                DateFormatter.formatDate(lastOrderDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            DateFormatter.getRelativeDate(lastOrderDate),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildClientOrders(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is OrdersLoaded) {
          final orders = state.orders;
          
          if (orders.isEmpty) {
            return const SizedBox(
              height: 200,
              child: EmptyStateWidget(
                message: 'No orders yet',
                subMessage: 'Create an order for this client',
                icon: Icons.shopping_cart_outlined,
              ),
            );
          }
          
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _buildOrderStatusIcon(order.status),
                  title: Text(
                    'Order #${order.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateFormatter.formatDate(order.orderDate),
                  ),
                  trailing: Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/orders/detail',
                      arguments: order.id,
                    );
                  },
                ),
              );
            },
          );
        } else if (state is OrderError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(state.message),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildOrderStatusIcon(String status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'New':
        icon = Icons.fiber_new;
        color = Colors.blue;
        break;
      case 'Processing':
        icon = Icons.hourglass_top;
        color = Colors.orange;
        break;
      case 'Completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'Cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.shopping_cart;
        color = Colors.grey;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }
  
  Color _getClientTypeColor(String type) {
    switch (type) {
      case 'VIP':
        return Colors.amber[700]!;
      case 'New':
        return Colors.blue[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
  
  void _editClient(BuildContext context, Client client) {
    Navigator.pushNamed(
      context,
      '/clients/edit',
      arguments: client,
    );
  }
  
  void _confirmDelete(BuildContext context, Client client) {
    ConfirmationDialog.showDeleteConfirmation(
      context: context,
      itemType: 'Client',
      itemName: client.name,
      onConfirm: () {
        context.read<ClientBloc>().add(DeleteClient(client.id!));
      },
    );
  }
}
