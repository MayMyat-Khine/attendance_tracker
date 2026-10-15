import 'package:attendance_tracker/core/error/failure.dart';
import 'package:bloc/bloc.dart';

import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/get_user_history.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/sync_pending_logs.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/history_event.dart';
import 'package:attendance_tracker/features/attendance/presentation/bloc/history_state.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/get_signed_in_user.dart';

final class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({
    required this._getSignedInUser,
    required this._getUserHistory,
    required this._syncPendingLogs,
  }) : super(const HistoryLoading()) {
    on<HistoryStarted>(_onLoad);
    on<HistoryRefreshed>(_onLoad);
    add(const HistoryStarted());
  }

  final GetSignedInUser _getSignedInUser;
  final GetUserHistory _getUserHistory;
  final SyncPendingLogs _syncPendingLogs;

  Future<void> _onLoad(HistoryEvent event, Emitter<HistoryState> emit) async {
    if (event is HistoryRefreshed && state is HistoryLoading) {
      return;
    }
    final sync = await _syncPendingLogs();
    final syncFailure = switch (sync) {
      ResultFailure(:final failure) when failure is! NetworkFailure => failure,
      _ => null,
    };
    final userResult = await _getSignedInUser();
    switch (userResult) {
      case ResultFailure(:final failure):
        emit(HistoryFailure(failure));
      case Success(:final value) when value == null:
        emit(const HistorySignedOut());
      case Success(:final value):
        final user = value;
        if (user == null) {
          emit(const HistorySignedOut());
          return;
        }
        final historyResult = await _getUserHistory(email: user.email);
        switch (historyResult) {
          case ResultFailure(:final failure):
            emit(HistoryFailure(failure));
          case Success(:final value):
            emit(HistoryReady(value.savedDays, failure: syncFailure));
        }
    }
  }
}
