import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/features/invoices/models/invoice.dart';
import 'package:supplier_management/features/invoices/repository/invoice_repository.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/repository/order_repository.dart';

// Events
abstract class InvoiceEvent {}

class LoadInvoices extends InvoiceEvent {}

class LoadInvoicesByStatus extends InvoiceEvent {
  final String status;

  LoadInvoicesByStatus(this.status);
}

class LoadInvoiceById extends InvoiceEvent {
  final int id;

  LoadInvoiceById(this.id);
}

class GenerateInvoice extends InvoiceEvent {
  final int orderId;

  GenerateInvoice(this.orderId);
}

class UpdateInvoicePaymentStatus extends InvoiceEvent {
  final int id;
  final String status;
  final DateTime? paymentDate;

  UpdateInvoicePaymentStatus(this.id, this.status, {this.paymentDate});
}

class ShareInvoice extends InvoiceEvent {
  final String filePath;

  ShareInvoice(this.filePath);
}

class PrintInvoice extends InvoiceEvent {
  final String filePath;

  PrintInvoice(this.filePath);
}

// States
abstract class InvoiceState {}

class InvoiceInitial extends InvoiceState {}

class InvoicesLoading extends InvoiceState {}

class InvoicesLoaded extends InvoiceState {
  final List<Invoice> invoices;
  final String? filterStatus;

  InvoicesLoaded(this.invoices, {this.filterStatus});
}

class InvoiceDetails extends InvoiceState {
  final Invoice invoice;
  final Order order;
  final dynamic client;
  final List<dynamic> orderItems;

  InvoiceDetails(this.invoice, this.order, this.client, this.orderItems);
}

class InvoiceGenerated extends InvoiceState {
  final Invoice invoice;

  InvoiceGenerated(this.invoice);
}

class InvoiceOperationSuccess extends InvoiceState {
  final String message;

  InvoiceOperationSuccess(this.message);
}

class InvoiceError extends InvoiceState {
  final String message;

  InvoiceError(this.message);
}

// BLoC
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceRepository _invoiceRepository;
  final OrderRepository _orderRepository;

  InvoiceBloc(this._invoiceRepository, this._orderRepository) : super(InvoiceInitial()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<LoadInvoicesByStatus>(_onLoadInvoicesByStatus);
    on<LoadInvoiceById>(_onLoadInvoiceById);
    on<GenerateInvoice>(_onGenerateInvoice);
    on<UpdateInvoicePaymentStatus>(_onUpdateInvoicePaymentStatus);
    on<ShareInvoice>(_onShareInvoice);
    on<PrintInvoice>(_onPrintInvoice);
  }

  Future<void> _onLoadInvoices(
    LoadInvoices event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoicesLoading());
    try {
      final invoices = await _invoiceRepository.getAllInvoices();
      emit(InvoicesLoaded(invoices));
    } catch (e) {
      emit(InvoiceError('Failed to load invoices: ${e.toString()}'));
    }
  }

  Future<void> _onLoadInvoicesByStatus(
    LoadInvoicesByStatus event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoicesLoading());
    try {
      final invoices = await _invoiceRepository.getInvoicesByPaymentStatus(event.status);
      emit(InvoicesLoaded(invoices, filterStatus: event.status));
    } catch (e) {
      emit(InvoiceError('Failed to load invoices: ${e.toString()}'));
    }
  }

  Future<void> _onLoadInvoiceById(
    LoadInvoiceById event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoicesLoading());
    try {
      final details = await _invoiceRepository.getInvoiceDetails(event.id);
      emit(InvoiceDetails(
        details['invoice'],
        details['order'],
        details['client'],
        details['orderItems'],
      ));
    } catch (e) {
      emit(InvoiceError('Failed to load invoice: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateInvoice(
    GenerateInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoicesLoading());
    try {
      final invoice = await _invoiceRepository.generateInvoice(event.orderId);
      emit(InvoiceGenerated(invoice));
    } catch (e) {
      emit(InvoiceError('Failed to generate invoice: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateInvoicePaymentStatus(
    UpdateInvoicePaymentStatus event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoicesLoading());
    try {
      await _invoiceRepository.updatePaymentStatus(
        event.id,
        event.status,
        paymentDate: event.paymentDate,
      );
      emit(InvoiceOperationSuccess('Payment status updated to ${event.status}'));
      
      // Reload invoice details
      add(LoadInvoiceById(event.id));
    } catch (e) {
      emit(InvoiceError('Failed to update payment status: ${e.toString()}'));
    }
  }

  Future<void> _onShareInvoice(
    ShareInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      await _invoiceRepository.shareInvoice(event.filePath);
      emit(InvoiceOperationSuccess('Invoice shared successfully'));
    } catch (e) {
      emit(InvoiceError('Failed to share invoice: ${e.toString()}'));
    }
  }

  Future<void> _onPrintInvoice(
    PrintInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      await _invoiceRepository.printInvoice(event.filePath);
      emit(InvoiceOperationSuccess('Invoice sent to printer'));
    } catch (e) {
      emit(InvoiceError('Failed to print invoice: ${e.toString()}'));
    }
  }
}
