import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';

abstract class AttendanceRepository {
  Future<Result<List<AttendanceRecord>>> getHistory({required String email});

  Future<Result<AttendanceRecord>> checkIn({
    required String email,
    required GeoLocation location,
    String? date,
  });

  Future<Result<AttendanceRecord>> checkOut({
    required String email,
    required GeoLocation location,
  });

  Future<Result<Unit>> syncPendingLogs();
}
