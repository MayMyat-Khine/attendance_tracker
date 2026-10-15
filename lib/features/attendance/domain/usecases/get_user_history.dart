import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/user_history.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/attendance_repository.dart';

final class GetUserHistory {
  const GetUserHistory(this._repository);

  final AttendanceRepository _repository;

  Future<Result<UserHistory>> call({required String email}) async {
    final history = await _repository.getHistory(email: email);
    switch (history) {
      case ResultFailure<List<AttendanceRecord>>(:final failure):
        return ResultFailure(failure);
      case Success<List<AttendanceRecord>>(:final value):
        return Success(
          buildCurrentMonthHistory(records: value, now: DateTime.now()),
        );
    }
  }
}
