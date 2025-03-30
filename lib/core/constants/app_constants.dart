class AppConstants {
  // App Information
  static const String appName = 'Supplier Management';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'supplier_management.db';
  static const int databaseVersion = 1;
  
  // Table Names
  static const String productsTable = 'products';
  static const String clientsTable = 'clients';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';
  static const String invoicesTable = 'invoices';
  
  // Order Status
  static const String orderStatusNew = 'New';
  static const String orderStatusProcessing = 'Processing';
  static const String orderStatusCompleted = 'Completed';
  static const String orderStatusCancelled = 'Cancelled';
  
  static const List<String> orderStatusList = [
    orderStatusNew,
    orderStatusProcessing,
    orderStatusCompleted,
    orderStatusCancelled,
  ];
  
  // Payment Status
  static const String paymentStatusPending = 'Pending';
  static const String paymentStatusPaid = 'Paid';
  static const String paymentStatusOverdue = 'Overdue';
  static const String paymentStatusPartial = 'Partial';
  static const String paymentStatusCancelled = 'Cancelled';
  
  static const List<String> paymentStatusList = [
    paymentStatusPending,
    paymentStatusPaid,
    paymentStatusOverdue,
    paymentStatusPartial,
    paymentStatusCancelled,
  ];
  
  // Client Types
  static const String clientTypeRegular = 'Regular';
  static const String clientTypeVIP = 'VIP';
  static const String clientTypeNew = 'New';
  
  static const List<String> clientTypeList = [
    clientTypeRegular,
    clientTypeVIP,
    clientTypeNew,
  ];
  
  // Report Periods
  static const String reportPeriodDaily = 'Daily';
  static const String reportPeriodWeekly = 'Weekly';
  static const String reportPeriodMonthly = 'Monthly';
  static const String reportPeriodYearly = 'Yearly';
  
  static const List<String> reportPeriodList = [
    reportPeriodDaily,
    reportPeriodWeekly,
    reportPeriodMonthly,
    reportPeriodYearly,
  ];
  
  // Default Values
  static const int defaultMinStockLevel = 5;
  
  // Error Messages
  static const String errorDatabaseInit = 'Failed to initialize database';
  static const String errorNoData = 'No data available';
  static const String errorCreatingOrder = 'Failed to create order';
  static const String errorUpdatingOrder = 'Failed to update order';
  static const String errorGeneratingInvoice = 'Failed to generate invoice';
  static const String errorScanningBarcode = 'Failed to scan barcode';
  
  // Success Messages
  static const String successProductAdded = 'Product added successfully';
  static const String successProductUpdated = 'Product updated successfully';
  static const String successProductDeleted = 'Product deleted successfully';
  static const String successClientAdded = 'Client added successfully';
  static const String successClientUpdated = 'Client updated successfully';
  static const String successClientDeleted = 'Client deleted successfully';
  static const String successOrderCreated = 'Order created successfully';
  static const String successOrderUpdated = 'Order updated successfully';
  static const String successOrderDeleted = 'Order deleted successfully';
  static const String successInvoiceGenerated = 'Invoice generated successfully';
  static const String successInvoiceSent = 'Invoice sent successfully';
  static const String successPaymentRecorded = 'Payment recorded successfully';
}
