import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/app.dart';
import 'package:supplier_management/core/database/database_helper.dart';
import 'package:supplier_management/features/clients/bloc/client_bloc.dart';
import 'package:supplier_management/features/clients/repository/client_repository.dart';
import 'package:supplier_management/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:supplier_management/features/dashboard/repository/dashboard_repository.dart';
import 'package:supplier_management/features/invoices/bloc/invoice_bloc.dart';
import 'package:supplier_management/features/invoices/repository/invoice_repository.dart';
import 'package:supplier_management/features/orders/bloc/order_bloc.dart';
import 'package:supplier_management/features/orders/repository/order_repository.dart';
import 'package:supplier_management/features/products/bloc/product_bloc.dart';
import 'package:supplier_management/features/products/repository/product_repository.dart';
import 'package:supplier_management/features/reports/bloc/report_bloc.dart';
import 'package:supplier_management/features/reports/repository/report_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize database
  final databaseHelper = DatabaseHelper();
  await databaseHelper.initializeDatabase();
  
  // Initialize repositories
  final productRepository = ProductRepository(databaseHelper);
  final clientRepository = ClientRepository(databaseHelper);
  final orderRepository = OrderRepository(databaseHelper);
  final invoiceRepository = InvoiceRepository(databaseHelper);
  final dashboardRepository = DashboardRepository(databaseHelper);
  final reportRepository = ReportRepository(databaseHelper);
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(productRepository),
        ),
        BlocProvider<ClientBloc>(
          create: (context) => ClientBloc(clientRepository),
        ),
        BlocProvider<OrderBloc>(
          create: (context) => OrderBloc(
            orderRepository,
            productRepository,
            clientRepository,
          ),
        ),
        BlocProvider<InvoiceBloc>(
          create: (context) => InvoiceBloc(
            invoiceRepository,
            orderRepository,
          ),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(dashboardRepository),
        ),
        BlocProvider<ReportBloc>(
          create: (context) => ReportBloc(reportRepository),
        ),
      ],
      child: const SupplierManagementApp(),
    ),
  );
}
