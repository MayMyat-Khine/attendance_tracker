import 'package:attendance_tracker/features/attendance/data/models/attendance_record_model.dart';

abstract class AttendanceRemoteDataSource {
  String ownerKey(String email);
  String? get currentUserId;
  Future<List<AttendanceRecordModel>> fetchByEmail(String email);
  Future<void> applyCheckIn({
    required String email,
    required String date,
    required String time,
    required double latitude,
    required double longitude,
    required int createdAt,
    required String operationId,
  });
  Future<void> applyCheckOut({
    required String email,
    required String date,
    required String time,
    required double latitude,
    required double longitude,
    required int createdAt,
    required String operationId,
  });
}
