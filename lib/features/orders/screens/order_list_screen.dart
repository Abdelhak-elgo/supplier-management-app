import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/widgets/app_drawer.dart';
import 'package:supplier_management/core/widgets/empty_state_widget.dart';
import 'package:supplier_management/core/widgets/error_widget.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/features/orders/bloc/order_bloc.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/widgets/order_card.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadOrders();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      return;
    }
    
    switch (_tabController.index) {
      case 0:
        context.read<OrderBloc>().add(LoadOrders());
        break;
      case 1:
        context.read<OrderBloc>().add(LoadOrdersByStatus(AppConstants.orderStatusNew));
        break;
      case 2:
        context.read<OrderBloc>().add(LoadOrdersByStatus(AppConstants.orderStatusProcessing));
        break;
      case 3:
        context.read<OrderBloc>().add(LoadOrdersByStatus(AppConstants.orderStatusCompleted));
        break;
    }
  }
  
  void _loadOrders() {
    context.read<OrderBloc>().add(LoadOrders());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'New'),
            Tab(text: 'Processing'),
            Tab(text: 'Completed'),
          ],
          isScrollable: true,
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(null),
          _buildOrderList(AppConstants.orderStatusNew),
          _buildOrderList(AppConstants.orderStatusProcessing),
          _buildOrderList(AppConstants.orderStatusCompleted),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/orders/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildOrderList(String? status) {
    return BlocConsumer<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is OrderOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          
          // Reload orders after operation
          if (status == null) {
            context.read<OrderBloc>().add(LoadOrders());
          } else {
            context.read<OrderBloc>().add(LoadOrdersByStatus(status));
          }
        }
      },
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const LoadingWidget();
        } else if (state is OrdersLoaded) {
          final orders = state.orders;
          
          // Filter orders based on status if needed
          final filteredOrders = status == null
              ? orders
              : orders.where((order) => order.status == status).toList();
          
          return _buildOrdersList(filteredOrders);
        } else if (state is OrderError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () {
              if (status == null) {
                context.read<OrderBloc>().add(LoadOrders());
              } else {
                context.read<OrderBloc>().add(LoadOrdersByStatus(status));
              }
            },
          );
        }
        
        return const LoadingWidget();
      },
    );
  }
  
  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return EmptyStateWidget(
        message: 'No orders found',
        subMessage: 'Create a new order to get started',
        icon: Icons.shopping_cart_outlined,
        onAction: () {
          Navigator.pushNamed(context, '/orders/add');
        },
        actionLabel: 'Create Order',
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return OrderCard(
            order: orders[index],
            onTap: () {
              Navigator.pushNamed(
                context,
                '/orders/detail',
                arguments: orders[index].id,
              );
            },
          );
        },
      ),
    );
  }
}
