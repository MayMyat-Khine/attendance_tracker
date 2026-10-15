import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/usecases/get_dashboard_summary.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

final class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

sealed class DashboardState {
  const DashboardState();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardReady extends DashboardState {
  const DashboardReady(this.summary, {this.failure});
  final DashboardSummary? summary;
  final Failure? failure;
}

final class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._getSummary) : super(const DashboardLoading()) {
    on<DashboardRefreshed>((event, emit) async {
      if (_loading) return;
      _loading = true;
      final previous = state;
      final result = await _getSummary();
      _loading = false;
      switch (result) {
        case Success(:final value):
          emit(DashboardReady(value));
        case ResultFailure(:final failure):
          emit(
            DashboardReady(
              previous is DashboardReady ? previous.summary : null,
              failure: failure,
            ),
          );
      }
    });
    add(const DashboardRefreshed());
  }
  final GetDashboardSummary _getSummary;
  bool _loading = false;
}
