import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/features/attendance/data/models/attendance_record_model.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';

final class FirebaseAttendanceRemoteDataSource {
  FirebaseAttendanceRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'history';

  Future<List<AttendanceRecordModel>> fetchByEmail(String email) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return const [];
    }
    return _recordsFrom(snapshot.docs.first.data());
  }

  Future<void> applyCheckIn({
    required String email,
    required String date,
    required String time,
    required double latitude,
    required double longitude,
  }) {
    return _transaction(email, (records) {
      if (_alreadyCheckedIn(records, date)) {
        return records;
      }
      if (_openIndex(records) != -1) {
        throw const AttendanceConflictException(checkOutBeforeCheckInMessage);
      }
      if (_isComplete(records, date)) {
        throw const AttendanceConflictException(alreadyCheckedOutMessage);
      }
      return [
        ...records,
        <String, dynamic>{
          'date': date,
          'checkin': time,
          'checkout': '',
          'location': GeoPoint(latitude, longitude),
        },
      ];
    });
  }

  Future<void> applyCheckOut({
    required String email,
    required String date,
    required String time,
  }) {
    return _transaction(email, (records) {
      final dated = _indexForDate(records, date);
      if (dated != -1 && _string(records[dated]['checkout']).isNotEmpty) {
        return records;
      }
      final open = dated != -1 && _string(records[dated]['checkin']).isNotEmpty
          ? dated
          : _openIndex(records);
      if (open == -1) {
        return records;
      }
      final current = Map<String, dynamic>.from(records[open]);
      current['checkout'] = time;
      final next = [...records];
      next[open] = current;
      return next;
    });
  }

  Future<void> _transaction(
    String email,
    List<Map<String, dynamic>> Function(List<Map<String, dynamic>> records)
    update,
  ) async {
    final existing = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    final ref = existing.docs.isEmpty
        ? _firestore.collection(_collection).doc(email)
        : existing.docs.first.reference;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final records = _rawRecords(snapshot.data());
      final next = update(records);
      transaction.set(ref, <String, dynamic>{'email': email, 'records': next});
    });
  }

  List<AttendanceRecordModel> _recordsFrom(Map<String, dynamic> data) {
    return [
      for (final record in _rawRecords(data))
        AttendanceRecordModel.fromMap(record),
    ];
  }

  List<Map<String, dynamic>> _rawRecords(Map<String, dynamic>? data) {
    final raw = data?['records'];
    if (raw is! List) {
      return [];
    }
    return [
      for (final item in raw)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  int _indexForDate(List<Map<String, dynamic>> records, String date) {
    for (var index = 0; index < records.length; index++) {
      if (_string(records[index]['date']) == date) {
        return index;
      }
    }
    return -1;
  }

  int _openIndex(List<Map<String, dynamic>> records) {
    for (var index = 0; index < records.length; index++) {
      if (_string(records[index]['checkin']).isNotEmpty &&
          _string(records[index]['checkout']).isEmpty) {
        return index;
      }
    }
    return -1;
  }

  bool _alreadyCheckedIn(List<Map<String, dynamic>> records, String date) {
    final index = _indexForDate(records, date);
    if (index == -1) {
      return false;
    }
    return _string(records[index]['checkin']).isNotEmpty;
  }

  bool _isComplete(List<Map<String, dynamic>> records, String date) {
    final index = _indexForDate(records, date);
    if (index == -1) {
      return false;
    }
    return _string(records[index]['checkin']).isNotEmpty &&
        _string(records[index]['checkout']).isNotEmpty;
  }

  String _string(Object? value) {
    if (value is! String) {
      return '';
    }
    return value;
  }
}
