import 'package:flutter/material.dart';
import 'package:supplier_management/core/theme/app_theme.dart';
import 'package:supplier_management/core/widgets/app_drawer.dart';
import 'package:supplier_management/features/dashboard/screens/dashboard_screen.dart';
import 'package:supplier_management/features/products/screens/product_list_screen.dart';
import 'package:supplier_management/features/products/screens/add_edit_product_screen.dart';
import 'package:supplier_management/features/products/screens/product_detail_screen.dart';
import 'package:supplier_management/features/clients/screens/client_list_screen.dart';
import 'package:supplier_management/features/clients/screens/add_edit_client_screen.dart';
import 'package:supplier_management/features/clients/screens/client_detail_screen.dart';
import 'package:supplier_management/features/orders/screens/order_list_screen.dart';
import 'package:supplier_management/features/orders/screens/add_edit_order_screen.dart';
import 'package:supplier_management/features/orders/screens/order_detail_screen.dart';
import 'package:supplier_management/features/invoices/screens/invoice_list_screen.dart';
import 'package:supplier_management/features/invoices/screens/invoice_detail_screen.dart';
import 'package:supplier_management/features/reports/screens/report_screen.dart';

class SupplierManagementApp extends StatelessWidget {
  const SupplierManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supplier Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/products': (context) => const ProductListScreen(),
        '/products/add': (context) => const AddEditProductScreen(),
        '/products/edit': (context) => const AddEditProductScreen(isEditing: true),
        '/products/detail': (context) => const ProductDetailScreen(),
        '/clients': (context) => const ClientListScreen(),
        '/clients/add': (context) => const AddEditClientScreen(),
        '/clients/edit': (context) => const AddEditClientScreen(isEditing: true),
        '/clients/detail': (context) => const ClientDetailScreen(),
        '/orders': (context) => const OrderListScreen(),
        '/orders/add': (context) => const AddEditOrderScreen(),
        '/orders/edit': (context) => const AddEditOrderScreen(isEditing: true),
        '/orders/detail': (context) => const OrderDetailScreen(),
        '/invoices': (context) => const InvoiceListScreen(),
        '/invoices/detail': (context) => const InvoiceDetailScreen(),
        '/reports': (context) => const ReportScreen(),
      },
    );
  }
}
