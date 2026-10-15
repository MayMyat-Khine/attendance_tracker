import 'package:attendance_tracker/core/config/app_environment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/features/attendance/data/models/attendance_record_model.dart';
import 'package:attendance_tracker/features/attendance/domain/attendance_time.dart';

final class FirebaseAttendanceRemoteDataSource
    implements AttendanceRemoteDataSource {
  FirebaseAttendanceRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  @override
  String ownerKey(String email) {
    final user = _auth.currentUser;
    if (user == null || user.email?.toLowerCase() != email.toLowerCase()) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    return user.uid;
  }

  @override
  String? get currentUserId => _auth.currentUser?.uid;
  @override
  Future<List<AttendanceRecordModel>> fetchByEmail(String email) async {
    final uid = ownerKey(email);
    final snapshot = await _firestore
        .collection(AppConfig.attendance)
        .where('userId', isEqualTo: uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 8));
    return [
      for (final doc in snapshot.docs)
        AttendanceRecordModel.fromMap(doc.data()),
    ];
  }

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
    final uid = ownerKey(email);
    final day = _firestore.collection(AppConfig.attendance).doc('${uid}_$date');
    final session = _firestore.collection(AppConfig.sessions).doc(uid);
    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(day);
      final active = await tx.get(session);
      if (existing.exists) {
        if (existing.data()?['checkInOperationId'] == operationId) return;
        throw const AttendanceConflictException(alreadyCheckedOutMessage);
      }
      if ((active.data()?['openDate'] ?? '') != '') {
        throw const AttendanceConflictException(checkOutBeforeCheckInMessage);
      }
      tx.set(day, <String, Object?>{
        'userId': uid,
        'email': email,
        'date': date,
        'checkin': time,
        'checkout': '',
        'checkInAt': Timestamp.fromMicrosecondsSinceEpoch(createdAt),
        'checkOutAt': null,
        'location': GeoPoint(latitude, longitude),
        'checkOutLocation': null,
        'checkInOperationId': operationId,
        'checkOutOperationId': null,
      });
      tx.set(session, {'openDate': date});
    });
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
    final uid = ownerKey(email);
    final day = _firestore.collection(AppConfig.attendance).doc('${uid}_$date');
    final session = _firestore.collection(AppConfig.sessions).doc(uid);
    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(day);
      final active = await tx.get(session);
      final data = existing.data();
      if (data?['checkOutOperationId'] == operationId) return;
      if (data == null || active.data()?['openDate'] != date) {
        throw const AttendanceConflictException(checkInBeforeCheckOutMessage);
      }
      if (data['checkOutAt'] != null) {
        throw const AttendanceConflictException(alreadyCheckedOutMessage);
      }
      final checkInAt = data['checkInAt'];
      if (checkInAt is! Timestamp ||
          createdAt < checkInAt.microsecondsSinceEpoch) {
        throw const AttendanceConflictException(
          'Check-out time must follow check-in. Check your device clock.',
        );
      }
      tx.update(day, <String, Object?>{
        'checkout': time,
        'checkOutAt': Timestamp.fromMicrosecondsSinceEpoch(createdAt),
        'checkOutLocation': GeoPoint(latitude, longitude),
        'checkOutOperationId': operationId,
      });
      tx.set(session, {'openDate': ''});
    });
  }
}
