import 'dart:async';
import 'dart:convert';

import 'attendance_persistence_io.dart'
    if (dart.library.js_interop) 'attendance_persistence_web.dart'
    as persistence;

import 'package:attendance_tracker/features/attendance/data/models/attendance_record_model.dart';
import 'package:attendance_tracker/features/attendance/data/models/pending_attendance_op.dart';

final class PendingAttendanceStore {
  PendingAttendanceStore({
    this.readPayload = persistence.readPayload,
    this.writePayload = persistence.writePayload,
  });
  final Future<String?> Function() readPayload;
  final Future<void> Function(String) writePayload;

  Future<void> _lock = Future<void>.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _lock = _lock.then((_) async {
      try {
        completer.complete(await persistence.withPersistenceLock(action));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<List<PendingAttendanceOp>> readPending() async {
    final stored = await _read();
    return stored.pending;
  }

  Future<List<AttendanceRecordModel>> readCache(String email) async {
    final stored = await _read();
    return stored.caches[email] ?? const [];
  }

  Future<void> writeCache({
    required String email,
    required List<AttendanceRecordModel> records,
  }) async {
    final stored = await _read();
    stored.caches[email] = records;
    await _write(stored);
  }

  Future<void> addPending(PendingAttendanceOp op) async {
    final stored = await _read();
    stored.pending.add(op);
    await _write(stored);
  }

  Future<void> removePending(String id) async {
    final stored = await _read();
    stored.pending.removeWhere((op) => op.id == id);
    await _write(stored);
  }

  Future<_StoredAttendance> _read() async {
    final payload = await readPayload();
    if (payload == null) {
      return _StoredAttendance();
    }
    final Object? decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return _StoredAttendance();
    }
    final map = Map<String, dynamic>.from(decoded);
    final pendingRaw = map['pending'];
    final cachesRaw = map['caches'];
    final pending = <PendingAttendanceOp>[];
    if (pendingRaw is List) {
      for (final item in pendingRaw) {
        if (item is Map) {
          pending.add(
            PendingAttendanceOp.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final caches = <String, List<AttendanceRecordModel>>{};
    if (cachesRaw is Map) {
      for (final entry in cachesRaw.entries) {
        final records = <AttendanceRecordModel>[];
        final value = entry.value;
        if (value is List) {
          for (final item in value) {
            if (item is Map) {
              records.add(
                AttendanceRecordModel.fromMap(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
        caches[entry.key.toString()] = records;
      }
    }
    return _StoredAttendance(pending: pending, caches: caches);
  }

  Future<void> _write(_StoredAttendance stored) async {
    final payload = <String, Object?>{
      'pending': [for (final op in stored.pending) op.toMap()],
      'caches': {
        for (final entry in stored.caches.entries)
          entry.key: [for (final record in entry.value) record.toCacheMap()],
      },
    };
    await writePayload(jsonEncode(payload));
  }
}

final class _StoredAttendance {
  _StoredAttendance({
    List<PendingAttendanceOp>? pending,
    Map<String, List<AttendanceRecordModel>>? caches,
  }) : pending = pending ?? <PendingAttendanceOp>[],
       caches = caches ?? <String, List<AttendanceRecordModel>>{};

  final List<PendingAttendanceOp> pending;
  final Map<String, List<AttendanceRecordModel>> caches;
}
