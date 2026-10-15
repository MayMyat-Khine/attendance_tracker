import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_day.dart';

sealed class HistoryState {
  const HistoryState();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistorySignedOut extends HistoryState {
  const HistorySignedOut();
}

final class HistoryFailure extends HistoryState {
  const HistoryFailure(this.failure);

  final Failure failure;
}

final class HistoryReady extends HistoryState {
  const HistoryReady(this.days, {this.failure});
  final Failure? failure;

  final List<AttendanceDay> days;
}
