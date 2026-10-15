import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/attendance_repository.dart';

final class SyncPendingLogs {
  const SyncPendingLogs(this._repository);

  final AttendanceRepository _repository;

  Future<Result<Unit>> call() => _repository.syncPendingLogs();
}
