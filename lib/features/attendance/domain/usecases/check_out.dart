import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/attendance_repository.dart';

final class CheckOut {
  const CheckOut(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceRecord>> call({required String email}) async {
    final history = await _repository.getHistory(email: email);
    switch (history) {
      case ResultFailure<List<AttendanceRecord>>(:final failure):
        return ResultFailure(failure);
      case Success<List<AttendanceRecord>>(:final value):
        if (openRecord(value) == null) {
          return const ResultFailure(
            ValidationFailure(checkInBeforeCheckOutMessage),
          );
        }
        return _repository.checkOut(email: email);
    }
  }
}
