import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/widgets/app_drawer.dart';
import 'package:supplier_management/core/widgets/empty_state_widget.dart';
import 'package:supplier_management/core/widgets/error_widget.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/features/invoices/bloc/invoice_bloc.dart';
import 'package:supplier_management/features/invoices/models/invoice.dart';
import 'package:supplier_management/features/invoices/widgets/invoice_card.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({Key? key}) : super(key: key);

  @override
  _InvoiceListScreenState createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadInvoices();
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
        context.read<InvoiceBloc>().add(LoadInvoices());
        break;
      case 1:
        context.read<InvoiceBloc>().add(LoadInvoicesByStatus(AppConstants.paymentStatusPending));
        break;
      case 2:
        context.read<InvoiceBloc>().add(LoadInvoicesByStatus(AppConstants.paymentStatusPaid));
        break;
    }
  }
  
  void _loadInvoices() {
    context.read<InvoiceBloc>().add(LoadInvoices());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoiceList(null),
          _buildInvoiceList(AppConstants.paymentStatusPending),
          _buildInvoiceList(AppConstants.paymentStatusPaid),
        ],
      ),
    );
  }
  
  Widget _buildInvoiceList(String? status) {
    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is InvoiceOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          
          // Reload invoices after operation
          if (status == null) {
            context.read<InvoiceBloc>().add(LoadInvoices());
          } else {
            context.read<InvoiceBloc>().add(LoadInvoicesByStatus(status));
          }
        }
      },
      builder: (context, state) {
        if (state is InvoicesLoading) {
          return const LoadingWidget();
        } else if (state is InvoicesLoaded) {
          final invoices = state.invoices;
          
          // Filter invoices if needed
          final filteredInvoices = status == null
              ? invoices
              : invoices.where((invoice) => invoice.paymentStatus == status).toList();
          
          return _buildInvoicesList(filteredInvoices);
        } else if (state is InvoiceError) {
          return AppErrorWidget(
            message: state.message,
            onRetry: () {
              if (status == null) {
                context.read<InvoiceBloc>().add(LoadInvoices());
              } else {
                context.read<InvoiceBloc>().add(LoadInvoicesByStatus(status));
              }
            },
          );
        }
        
        return const LoadingWidget();
      },
    );
  }
  
  Widget _buildInvoicesList(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return const EmptyStateWidget(
        message: 'No invoices found',
        subMessage: 'Create an order and generate an invoice',
        icon: Icons.receipt_long_outlined,
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadInvoices();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          return InvoiceCard(
            invoice: invoices[index],
            onTap: () {
              Navigator.pushNamed(
                context,
                '/invoices/detail',
                arguments: invoices[index].id,
              );
            },
          );
        },
      ),
    );
  }
}
