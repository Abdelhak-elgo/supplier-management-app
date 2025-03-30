import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/features/reports/models/sales_report.dart';
import 'package:supplier_management/features/reports/repository/report_repository.dart';

// Events
abstract class ReportEvent {}

class GenerateSalesReport extends ReportEvent {
  final DateTime startDate;
  final DateTime endDate;

  GenerateSalesReport({
    required this.startDate,
    required this.endDate,
  });
}

class GenerateInventoryReport extends ReportEvent {}

class GenerateClientReport extends ReportEvent {}

// States
abstract class ReportState {}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class SalesReportLoaded extends ReportState {
  final SalesReport report;

  SalesReportLoaded(this.report);
}

class InventoryReportLoaded extends ReportState {
  final Map<String, dynamic> report;

  InventoryReportLoaded(this.report);
}

class ClientReportLoaded extends ReportState {
  final Map<String, dynamic> report;

  ClientReportLoaded(this.report);
}

class ReportError extends ReportState {
  final String message;

  ReportError(this.message);
}

// BLoC
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;

  ReportBloc(this._reportRepository) : super(ReportInitial()) {
    on<GenerateSalesReport>(_onGenerateSalesReport);
    on<GenerateInventoryReport>(_onGenerateInventoryReport);
    on<GenerateClientReport>(_onGenerateClientReport);
  }

  Future<void> _onGenerateSalesReport(
    GenerateSalesReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final report = await _reportRepository.generateSalesReport(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(SalesReportLoaded(report));
    } catch (e) {
      emit(ReportError('Failed to generate sales report: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateInventoryReport(
    GenerateInventoryReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final report = await _reportRepository.getInventoryReport();
      emit(InventoryReportLoaded(report));
    } catch (e) {
      emit(ReportError('Failed to generate inventory report: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateClientReport(
    GenerateClientReport event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final report = await _reportRepository.getClientReport();
      emit(ClientReportLoaded(report));
    } catch (e) {
      emit(ReportError('Failed to generate client report: ${e.toString()}'));
    }
  }
}
