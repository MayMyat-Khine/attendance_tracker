import 'package:attendance_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/map_to_failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/core/network/network_info.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/pending_attendance_store.dart';
import 'package:attendance_tracker/features/attendance/data/models/pending_attendance_op.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/attendance_repository.dart';

final class AttendanceRepositoryImpl implements AttendanceRepository {
  const AttendanceRepositoryImpl({
    required this._remote,
    required this._authRepository,
    required this._store,
    required this._networkInfo,
  });

  final AttendanceRemoteDataSource _remote;
  final AuthRepository _authRepository;

  Future<void> _ensureEmployee([String? email]) async {
    final result = await _authRepository.currentUser();
    switch (result) {
      case ResultFailure(:final failure):
        throw OperationFailureException(failure);
      case Success(:final value):
        if (value == null ||
            value.role != UserRole.user ||
            (email != null &&
                value.email.toLowerCase() != email.toLowerCase())) {
          throw const AccessDeniedException();
        }
    }
  }

  final PendingAttendanceStore _store;
  final NetworkInfo _networkInfo;

  @override
  Future<Result<List<AttendanceRecord>>> getHistory({
    required String email,
  }) async {
    try {
      await _ensureEmployee(email);
      _remote.ownerKey(email);
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
      await _ensureEmployee(email);
      final record = await _store.synchronized(
        () => _enqueueCheckIn(email: email, location: location),
      );
      if (!await _networkInfo.isConnected) {
        return Success(record);
      }
      final synced = await syncPendingLogs();
      return switch (synced) {
        Success<Unit>() => Success(record),
        ResultFailure<Unit>(:final failure) when failure is NetworkFailure =>
          Success(record),
        ResultFailure<Unit>(:final failure) => ResultFailure(failure),
      };
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<AttendanceRecord>> checkOut({
    required String email,
    required GeoLocation location,
  }) async {
    try {
      await _ensureEmployee(email);
      final record = await _store.synchronized(
        () => _enqueueCheckOut(email: email, location: location),
      );
      if (!await _networkInfo.isConnected) {
        return Success(record);
      }
      final synced = await syncPendingLogs();
      return switch (synced) {
        Success<Unit>() => Success(record),
        ResultFailure<Unit>(:final failure) when failure is NetworkFailure =>
          Success(record),
        ResultFailure<Unit>(:final failure) => ResultFailure(failure),
      };
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<Unit>> syncPendingLogs() async {
    try {
      if (!await _networkInfo.isConnected) {
        return const ResultFailure(NetworkFailure());
      }
      await _ensureEmployee();
      await _store.synchronized(_uploadPending);
      return const Success(Unit());
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  Future<List<AttendanceRecord>> _merged(String email) async {
    final uid = _remote.ownerKey(email);
    final stored = await _stored(email);
    final pending = await _store.readPending();
    return _applyPending(
      stored,
      pending.where((op) => op.userId == uid).toList(),
    );
  }

  Future<List<AttendanceRecord>> _stored(String email) async {
    if (await _networkInfo.isConnected) {
      try {
        final remote = await _remote.fetchByEmail(email);
        await _store.writeCache(
          email: _remote.ownerKey(email),
          records: remote,
        );
        return [for (final record in remote) record.toEntity()];
      } catch (error) {
        // Offline or a flaky server still shows cached plus pending records,
        // but a denied or expired session must not hide behind stale data.
        if (mapToFailure(error) is PermissionFailure) rethrow;
      }
    }
    final cached = await _store.readCache(_remote.ownerKey(email));
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
    final recordDate = formatAttendanceDate(now);
    if (isDayComplete(merged, recordDate)) {
      throw const AttendanceConflictException(alreadyCheckedOutMessage);
    }
    final record = AttendanceRecord(
      date: recordDate,
      checkInAt: now.toUtc(),
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
        userId: _remote.ownerKey(email),
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

  Future<AttendanceRecord> _enqueueCheckOut({
    required String email,
    required GeoLocation location,
  }) async {
    final merged = await _merged(email);
    final open = openRecord(merged);
    if (open == null) {
      throw const AttendanceConflictException(checkInBeforeCheckOutMessage);
    }
    final now = DateTime.now();
    final time = formatAttendanceTime(now);
    if (open.checkInAt != null && now.toUtc().isBefore(open.checkInAt!)) {
      throw const AttendanceConflictException(
        'Check-out time must follow check-in. Check your device clock.',
      );
    }
    await _store.addPending(
      PendingAttendanceOp(
        id: now.toUtc().microsecondsSinceEpoch.toString(),
        email: email,
        userId: _remote.ownerKey(email),
        type: 'checkOut',
        date: open.date,
        time: time,
        latitude: location.latitude,
        longitude: location.longitude,
        createdAt: now.toUtc().microsecondsSinceEpoch,
      ),
    );
    return open.copyWith(
      checkOut: time,
      checkOutAt: now.toUtc(),
      checkOutLatitude: location.latitude,
      checkOutLongitude: location.longitude,
      pendingSync: true,
    );
  }

  Future<void> _uploadPending() async {
    final pending = await _store.readPending();
    final ordered =
        pending.where((op) => op.userId == _remote.currentUserId).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    AttendanceConflictException? rejected;
    for (final op in ordered) {
      try {
        await _uploadOne(op);
      } on AttendanceConflictException catch (error) {
        // The server will never accept this entry; drop it so later entries
        // still sync, and report it once.
        rejected ??= AttendanceConflictException(
          'An offline ${op.isCheckIn ? 'check-in' : 'check-out'} for '
          '${op.date} was not saved: ${error.message}',
        );
      }
      final remote = await _remote.fetchByEmail(op.email);
      await _store.writeCache(email: op.userId, records: remote);
      await _store.removePending(op.id);
    }
    if (rejected != null) throw rejected;
  }

  Future<void> _uploadOne(PendingAttendanceOp op) async {
    final latitude = op.latitude;
    final longitude = op.longitude;
    if (latitude == null || longitude == null) {
      throw AttendanceConflictException(
        op.isCheckIn
            ? checkOutBeforeCheckInMessage
            : 'Missing location in pending check-out.',
      );
    }
    final upload = op.isCheckIn ? _remote.applyCheckIn : _remote.applyCheckOut;
    await upload(
      email: op.email,
      date: op.date,
      time: op.time,
      createdAt: op.createdAt,
      operationId: op.id,
      latitude: latitude,
      longitude: longitude,
    ).timeout(const Duration(seconds: 12));
  }

  List<AttendanceRecord> _applyPending(
    List<AttendanceRecord> stored,
    List<PendingAttendanceOp> pending,
  ) {
    final records = [
      for (final record in stored)
        AttendanceRecord(
          date: record.date,
          checkInAt: record.checkInAt,
          checkOutAt: record.checkOutAt,
          checkOutLatitude: record.checkOutLatitude,
          checkOutLongitude: record.checkOutLongitude,
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
            checkInAt: DateTime.fromMicrosecondsSinceEpoch(
              op.createdAt,
              isUtc: true,
            ),
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
      final openIndex = dated;
      if (openIndex == -1) {
        continue;
      }
      records[openIndex] = records[openIndex].copyWith(
        checkOut: op.time,
        checkOutAt: DateTime.fromMicrosecondsSinceEpoch(
          op.createdAt,
          isUtc: true,
        ),
        checkOutLatitude: op.latitude,
        checkOutLongitude: op.longitude,
        pendingSync: true,
      );
    }
    return records;
  }
}
