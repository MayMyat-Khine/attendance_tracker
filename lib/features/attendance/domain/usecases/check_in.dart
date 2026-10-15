import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/attendance_repository.dart';

final class CheckInParams {
  const CheckInParams({
    required this.email,
    required this.location,
    this.date,
  });

  final String email;
  final GeoLocation location;
  final String? date;
}

final class CheckIn {
  const CheckIn(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceRecord>> call(CheckInParams params) async {
    final history = await _repository.getHistory(email: params.email);
    switch (history) {
      case ResultFailure<List<AttendanceRecord>>(:final failure):
        return ResultFailure(failure);
      case Success<List<AttendanceRecord>>(:final value):
        if (openRecord(value) != null) {
          return const ResultFailure(
            ValidationFailure(checkOutBeforeCheckInMessage),
          );
        }
        final today = params.date ?? formatAttendanceDate(DateTime.now());
        if (isDayComplete(value, today)) {
          return const ResultFailure(
            ValidationFailure(alreadyCheckedOutMessage),
          );
        }
        return _repository.checkIn(
          email: params.email,
          location: params.location,
          date: params.date,
        );
    }
  }
}
