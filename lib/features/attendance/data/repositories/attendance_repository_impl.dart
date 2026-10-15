import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/map_to_failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/core/network/network_info.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/firebase_attendance_remote_data_source.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/pending_attendance_store.dart';
import 'package:attendance_tracker/features/attendance/data/models/pending_attendance_op.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/attendance_repository.dart';

final class AttendanceRepositoryImpl implements AttendanceRepository {
  const AttendanceRepositoryImpl({
    required this._remote,
    required this._store,
    required this._networkInfo,
  });

  final FirebaseAttendanceRemoteDataSource _remote;
  final PendingAttendanceStore _store;
  final NetworkInfo _networkInfo;

  @override
  Future<Result<List<AttendanceRecord>>> getHistory({
    required String email,
  }) async {
    try {
      final records = await _store.synchronized(() => _merged(email));
      return Success(records);
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<AttendanceRecord>> checkIn({
    required String email,
    required GeoLocation location,
  }) async {
    try {
      final record = await _store.synchronized(
        () => _enqueueCheckIn(email: email, location: location),
      );
      if (!await _networkInfo.isConnected) {
        return Success(record);
      }
      final synced = await syncPendingLogs();
      return switch (synced) {
        Success<Unit>() => Success(record),
        ResultFailure<Unit>(:final failure) => ResultFailure(failure),
      };
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<AttendanceRecord>> checkOut({required String email}) async {
    try {
      final record = await _store.synchronized(
        () => _enqueueCheckOut(email: email),
      );
      if (!await _networkInfo.isConnected) {
        return Success(record);
      }
      final synced = await syncPendingLogs();
      return switch (synced) {
        Success<Unit>() => Success(record),
        ResultFailure<Unit>(:final failure) => ResultFailure(failure),
      };
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<Unit>> syncPendingLogs() async {
    if (!await _networkInfo.isConnected) {
      return const ResultFailure(NetworkFailure());
    }
    try {
      await _store.synchronized(_uploadPending);
      return const Success(Unit());
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  Future<List<AttendanceRecord>> _merged(String email) async {
    final stored = await _stored(email);
    final pending = await _store.readPending();
    return _applyPending(
      stored,
      pending.where((op) => op.email == email).toList(),
    );
  }

  Future<List<AttendanceRecord>> _stored(String email) async {
    if (await _networkInfo.isConnected) {
      try {
        final remote = await _remote.fetchByEmail(email);
        await _store.writeCache(email: email, records: remote);
        return [for (final record in remote) record.toEntity()];
      } catch (error) {
        if (mapToFailure(error) is! NetworkFailure) {
          rethrow;
        }
      }
    }
    final cached = await _store.readCache(email);
    return [for (final record in cached) record.toEntity()];
  }

  Future<AttendanceRecord> _enqueueCheckIn({
    required String email,
    required GeoLocation location,
  }) async {
    final merged = await _merged(email);
    if (openRecord(merged) != null) {
      throw const AttendanceConflictException(checkOutBeforeCheckInMessage);
    }
    final now = DateTime.now();
    final date = formatAttendanceDate(now);
    if (isDayComplete(merged, date)) {
      throw const AttendanceConflictException(alreadyCheckedOutMessage);
    }
    final record = AttendanceRecord(
      date: date,
      checkIn: formatAttendanceTime(now),
      checkOut: '',
      latitude: location.latitude,
      longitude: location.longitude,
      pendingSync: true,
    );
    await _store.addPending(
      PendingAttendanceOp(
        id: now.toUtc().microsecondsSinceEpoch.toString(),
        email: email,
        type: 'checkIn',
        date: record.date,
        time: record.checkIn,
        createdAt: now.toUtc().microsecondsSinceEpoch,
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );
    return record;
  }

  Future<AttendanceRecord> _enqueueCheckOut({required String email}) async {
    final merged = await _merged(email);
    final open = openRecord(merged);
    if (open == null) {
      throw const AttendanceConflictException(checkInBeforeCheckOutMessage);
    }
    final now = DateTime.now();
    final time = formatAttendanceTime(now);
    await _store.addPending(
      PendingAttendanceOp(
        id: now.toUtc().microsecondsSinceEpoch.toString(),
        email: email,
        type: 'checkOut',
        date: open.date,
        time: time,
        createdAt: now.toUtc().microsecondsSinceEpoch,
      ),
    );
    return open.copyWith(checkOut: time, pendingSync: true);
  }

  Future<void> _uploadPending() async {
    final pending = await _store.readPending();
    final ordered = [...pending]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final op in ordered) {
      if (op.isCheckIn) {
        final latitude = op.latitude;
        final longitude = op.longitude;
        if (latitude == null || longitude == null) {
          throw const AttendanceConflictException(checkOutBeforeCheckInMessage);
        }
        await _remote.applyCheckIn(
          email: op.email,
          date: op.date,
          time: op.time,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        await _remote.applyCheckOut(
          email: op.email,
          date: op.date,
          time: op.time,
        );
      }
      final remote = await _remote.fetchByEmail(op.email);
      await _store.writeCache(email: op.email, records: remote);
      await _store.removePending(op.id);
    }
  }

  List<AttendanceRecord> _applyPending(
    List<AttendanceRecord> stored,
    List<PendingAttendanceOp> pending,
  ) {
    final records = [
      for (final record in stored)
        AttendanceRecord(
          date: record.date,
          checkIn: record.checkIn,
          checkOut: record.checkOut,
          latitude: record.latitude,
          longitude: record.longitude,
        ),
    ];
    final ordered = [...pending]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final op in ordered) {
      if (op.isCheckIn) {
        final existing = records.indexWhere((record) => record.date == op.date);
        if (existing != -1 && records[existing].checkIn.isNotEmpty) {
          continue;
        }
        if (openRecord(records) != null || isDayComplete(records, op.date)) {
          continue;
        }
        records.add(
          AttendanceRecord(
            date: op.date,
            checkIn: op.time,
            checkOut: '',
            latitude: op.latitude,
            longitude: op.longitude,
            pendingSync: true,
          ),
        );
        continue;
      }
      final dated = records.indexWhere(
        (record) => record.date == op.date && record.isOpen,
      );
      final openIndex = dated != -1
          ? dated
          : records.indexWhere((record) => record.isOpen);
      if (openIndex == -1) {
        continue;
      }
      records[openIndex] = records[openIndex].copyWith(
        checkOut: op.time,
        pendingSync: true,
      );
    }
    return records;
  }
}
