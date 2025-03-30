import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/utils/date_formatter.dart';
import 'package:supplier_management/core/widgets/app_drawer.dart';
import 'package:supplier_management/core/widgets/empty_state_widget.dart';
import 'package:supplier_management/core/widgets/error_widget.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:supplier_management/features/dashboard/models/dashboard_stats.dart';
import 'package:supplier_management/features/dashboard/widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardBloc>().add(RefreshDashboardStats());
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(RefreshDashboardStats());
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardInitial || state is DashboardLoading) {
              return const LoadingWidget(
                message: 'Loading dashboard data...',
              );
            } else if (state is DashboardLoaded) {
              return _buildDashboard(context, state.stats);
            } else if (state is DashboardError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<DashboardBloc>().add(LoadDashboardStats());
                },
              );
            } else {
              return const AppErrorWidget(
                message: 'Unknown dashboard state',
              );
            }
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardStats stats) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: 24),
            _buildSummaryCards(context, stats),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Recent Orders'),
            const SizedBox(height: 8),
            _buildRecentOrders(context, stats.recentOrders),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final now = DateTime.now();
    String greeting;
    
    if (now.hour < 12) {
      greeting = 'Good Morning';
    } else if (now.hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormatter.formatDate(now),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        SummaryCard(
          title: 'Total Sales',
          value: '\$${stats.totalSales.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/reports'),
        ),
        SummaryCard(
          title: 'Pending Orders',
          value: stats.pendingOrders.toString(),
          icon: Icons.shopping_cart,
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, '/orders'),
        ),
        SummaryCard(
          title: 'Products',
          value: stats.totalProducts.toString(),
          icon: Icons.inventory,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/products'),
        ),
        SummaryCard(
          title: 'Low Stock',
          value: stats.lowStockProducts.toString(),
          icon: Icons.warning_amber,
          color: Colors.red,
          onTap: () => Navigator.pushNamed(context, '/products'),
        ),
      ],
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

  Widget _buildRecentOrders(BuildContext context, List<RecentOrder> recentOrders) {
    if (recentOrders.isEmpty) {
      return const EmptyStateWidget(
        message: 'No recent orders',
        subMessage: 'New orders will appear here',
        icon: Icons.shopping_cart_outlined,
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: recentOrders.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = recentOrders[index];
          return ListTile(
            title: Text(
              order.clientName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              DateFormatter.formatDate(order.orderDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/orders/detail',
                arguments: order.id,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Quick Actions'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionButton(
              context,
              icon: Icons.add_shopping_cart,
              label: 'New Order',
              onPressed: () => Navigator.pushNamed(context, '/orders/add'),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.inventory_2,
              label: 'Add Product',
              onPressed: () => Navigator.pushNamed(context, '/products/add'),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.person_add,
              label: 'Add Client',
              onPressed: () => Navigator.pushNamed(context, '/clients/add'),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.assessment,
              label: 'Reports',
              onPressed: () => Navigator.pushNamed(context, '/reports'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/orders/add'),
      icon: const Icon(Icons.add_shopping_cart),
      label: const Text('New Order'),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
