import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/features/dashboard/models/dashboard_stats.dart';
import 'package:supplier_management/features/dashboard/repository/dashboard_repository.dart';

// Events
abstract class DashboardEvent {}

class LoadDashboardStats extends DashboardEvent {}

class RefreshDashboardStats extends DashboardEvent {}

// States
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;

  DashboardLoaded(this.stats);
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;

  DashboardBloc(this._dashboardRepository) : super(DashboardInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<RefreshDashboardStats>(_onRefreshDashboardStats);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final stats = await _dashboardRepository.getDashboardStats();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard stats: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDashboardStats(
    RefreshDashboardStats event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // Don't emit loading state to avoid UI flicker
      final stats = await _dashboardRepository.getDashboardStats();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError('Failed to refresh dashboard stats: ${e.toString()}'));
    }
  }
}
