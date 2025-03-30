class Invoice {
  final int? id;
  final int orderId;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final String paymentStatus;
  final DateTime? paymentDate;
  final String? pdfPath;
  
  // Not stored in database, but useful for UI
  final String? clientName;
  final double? orderTotal;

  Invoice({
    this.id,
    required this.orderId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.paymentStatus,
    this.paymentDate,
    this.pdfPath,
    this.clientName,
    this.orderTotal,
  });

  Invoice copyWith({
    int? id,
    int? orderId,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    String? paymentStatus,
    DateTime? paymentDate,
    String? pdfPath,
    String? clientName,
    double? orderTotal,
  }) {
    return Invoice(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      pdfPath: pdfPath ?? this.pdfPath,
      clientName: clientName ?? this.clientName,
      orderTotal: orderTotal ?? this.orderTotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'invoice_number': invoiceNumber,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'payment_status': paymentStatus,
      'payment_date': paymentDate?.toIso8601String(),
      'pdf_path': pdfPath,
      'client_name': clientName,
      'order_total': orderTotal,
    };
  }

  Map<String, dynamic> toMapForDb() {
    final map = {
      'order_id': orderId,
      'invoice_number': invoiceNumber,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'payment_status': paymentStatus,
      'pdf_path': pdfPath,
    };

    if (id != null) {
      map['id'] = id;
    }

    if (paymentDate != null) {
      map['payment_date'] = paymentDate!.toIso8601String();
    }

    return map;
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      orderId: map['order_id'],
      invoiceNumber: map['invoice_number'] ?? '',
      issueDate: map['issue_date'] != null
          ? DateTime.parse(map['issue_date'])
          : DateTime.now(),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'])
          : DateTime.now().add(const Duration(days: 30)),
      paymentStatus: map['payment_status'] ?? 'Pending',
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'])
          : null,
      pdfPath: map['pdf_path'],
      clientName: map['client_name'],
      orderTotal: map['order_total'] != null
          ? (map['order_total'] as num).toDouble()
          : null,
    );
  }

  @override
  String toString() {
    return 'Invoice{id: $id, invoiceNumber: $invoiceNumber, orderId: $orderId, paymentStatus: $paymentStatus}';
  }
}
