import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/usecases/get_admin_history.dart';

sealed class UserHistoryEvent {
  const UserHistoryEvent();
}

final class UserHistoryRefreshed extends UserHistoryEvent {
  const UserHistoryRefreshed();
}

final class UserHistoryRangeChanged extends UserHistoryEvent {
  const UserHistoryRangeChanged(this.from, this.to);
  final DateTime from;
  final DateTime to;
}

final class UserHistoryNextPageRequested extends UserHistoryEvent {
  const UserHistoryNextPageRequested();
}

sealed class UserHistoryState {
  const UserHistoryState();
}

final class UserHistoryReady extends UserHistoryState {
  const UserHistoryReady({
    required this.from,
    required this.to,
    this.logs = const [],
    this.next,
    this.loading = false,
    this.failure,
  });
  final DateTime from;
  final DateTime to;
  final List<AdminLog> logs;
  final PageCursor? next;
  final bool loading;
  final Failure? failure;
}

final class UserHistoryBloc extends Bloc<UserHistoryEvent, UserHistoryState> {
  UserHistoryBloc(this._getHistory, {this.userId})
    : super(
        UserHistoryReady(
          from: DateTime(DateTime.now().year, DateTime.now().month),
          to: DateTime.now(),
          loading: true,
        ),
      ) {
    on<UserHistoryRefreshed>((event, emit) => _load(emit));
    on<UserHistoryRangeChanged>(
      (event, emit) => _load(emit, from: event.from, to: event.to),
    );
    on<UserHistoryNextPageRequested>((event, emit) async {
      final current = state as UserHistoryReady;
      if (!current.loading && current.next != null) {
        await _load(emit, append: true);
      }
    });
    add(const UserHistoryRefreshed());
  }
  final GetAdminHistory _getHistory;
  final String? userId;
  int _generation = 0;
  Future<void> _load(
    Emitter<UserHistoryState> emit, {
    DateTime? from,
    DateTime? to,
    bool append = false,
  }) async {
    final generation = ++_generation;
    final current = state as UserHistoryReady;
    final start = from ?? current.from;
    final end = to ?? current.to;
    emit(
      UserHistoryReady(
        from: start,
        to: end,
        logs: append ? current.logs : const [],
        loading: true,
      ),
    );
    final result = await _getHistory(
      userId: userId,
      from: start,
      to: end,
      after: append ? current.next : null,
    );
    if (generation != _generation || isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          UserHistoryReady(
            from: start,
            to: end,
            logs: [if (append) ...current.logs, ...value.logs],
            next: value.next,
          ),
        );
      case ResultFailure(:final failure):
        emit(
          UserHistoryReady(
            from: start,
            to: end,
            logs: append ? current.logs : const [],
            next: append ? current.next : null,
            failure: failure,
          ),
        );
    }
  }
}
