import 'dart:async';
import 'package:attendance_tracker/core/network/network_info.dart';
import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:attendance_tracker/features/attendance/data/models/attendance_record_model.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/pending_attendance_store.dart';

final class FakeNetwork implements NetworkInfo {
  bool online = false;
  @override
  Future<bool> get isConnected async => online;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

final class MemoryAttendance {
  String? payload;
  PendingAttendanceStore createStore() => PendingAttendanceStore(
    readPayload: () async => payload,
    writePayload: (value) async {
      payload = value;
    },
  );
}

final class FakeAttendanceRemote implements AttendanceRemoteDataSource {
  String? uid = 'user-1';
  String email = 'user@example.com';
  Object? uploadError;
  final records = <AttendanceRecordModel>[];
  final uploaded = <String>[];
  @override
  String? get currentUserId => uid;
  @override
  String ownerKey(String requestedEmail) {
    if (uid == null || requestedEmail != email) {
      throw const AccessDeniedException();
    }
    return uid!;
  }

  @override
  Future<List<AttendanceRecordModel>> fetchByEmail(String email) async =>
      List.of(records);
  @override
  Future<void> applyCheckIn({
    required String email,
    required String date,
    required String time,
    required double latitude,
    required double longitude,
    required int createdAt,
    required String operationId,
  }) async {
    if (uploadError case final error?) throw error;
    uploaded.add(operationId);
    records.add(
      AttendanceRecordModel(
        date: date,
        checkIn: time,
        checkOut: '',
        latitude: latitude,
        longitude: longitude,
        checkInAt: DateTime.fromMicrosecondsSinceEpoch(createdAt, isUtc: true),
      ),
    );
  }

  @override
  Future<void> applyCheckOut({
    required String email,
    required String date,
    required String time,
    required double latitude,
    required double longitude,
    required int createdAt,
    required String operationId,
  }) async {
    if (uploadError case final error?) throw error;
    uploaded.add(operationId);
    final index = records.indexWhere((record) => record.date == date);
    final previous = records[index];
    records[index] = AttendanceRecordModel(
      date: date,
      checkIn: previous.checkIn,
      checkOut: time,
      latitude: previous.latitude,
      longitude: previous.longitude,
      checkInAt: previous.checkInAt,
      checkOutAt: DateTime.fromMicrosecondsSinceEpoch(createdAt, isUtc: true),
      checkOutLatitude: latitude,
      checkOutLongitude: longitude,
    );
  }
}
