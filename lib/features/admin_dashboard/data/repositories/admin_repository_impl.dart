import 'package:attendance_tracker/core/config/app_environment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/map_to_failure.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:attendance_tracker/features/auth/data/models/app_user_model.dart';
import 'package:attendance_tracker/features/attendance/data/models/attendance_record_model.dart';

final class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.uid == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      }
      final profile = await _db
          .collection(AppConfig.users)
          .doc(user!.uid)
          .get(const GetOptions(source: Source.server));
      if (profile.data()?['role'] != 'admin') {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      }
      return Success(await action().timeout(const Duration(seconds: 15)));
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<DashboardSummary>> summary() => _run(() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toUtc();
    final end = DateTime(now.year, now.month, now.day + 1).toUtc();
    Future<int> count(String field) async {
      final result = await _db
          .collection(AppConfig.attendance)
          .where(field, isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where(field, isLessThan: Timestamp.fromDate(end))
          .count()
          .get();
      return result.count ?? 0;
    }

    final results = await Future.wait([
      _db.collection(AppConfig.users).count().get().then((v) => v.count ?? 0),
      count('checkInAt'),
      count('checkOutAt'),
    ]);
    return DashboardSummary(results[0], results[1], results[2]);
  });
  @override
  Future<Result<UsersPageData>> users({
    required String search,
    required bool byEmail,
    PageCursor? after,
  }) => _run(() async {
    final field = byEmail ? 'emailLower' : 'nameLower';
    Query<Map<String, Object?>> query = _db
        .collection(AppConfig.users)
        .orderBy(field)
        .orderBy(FieldPath.documentId);
    if (search.isNotEmpty) {
      query = query
          .where(field, isGreaterThanOrEqualTo: search)
          .where(field, isLessThanOrEqualTo: '$search\uf8ff');
    }
    if (after != null) query = query.startAfter([after.value, after.id]);
    final page = await query
        .limit(21)
        .get(const GetOptions(source: Source.server));
    final docs = page.docs.take(20).toList();
    final users = [
      for (final doc in docs)
        if (AppUserModel.fromFirestore(id: doc.id, data: doc.data())
            case final model?)
          model.toEntity(),
    ];
    return UsersPageData(
      users,
      page.docs.length > 20
          ? PageCursor(docs.last.data()[field] as String, docs.last.id)
          : null,
    );
  });
  @override
  Future<Result<LogsPageData>> history({
    String? userId,
    required DateTime from,
    required DateTime to,
    PageCursor? after,
  }) => _run(() async {
    final start = DateTime(from.year, from.month, from.day).toUtc();
    final end = DateTime(to.year, to.month, to.day + 1).toUtc();
    Query<Map<String, Object?>> query = _db.collection(AppConfig.attendance);
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    query = query
        .where('checkInAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('checkInAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('checkInAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (after != null) {
      query = query.startAfter([
        Timestamp.fromDate(DateTime.parse(after.value)),
        after.id,
      ]);
    }
    final page = await query
        .limit(31)
        .get(const GetOptions(source: Source.server));
    final docs = page.docs.take(30).toList();
    final logs = [
      for (final doc in docs)
        AdminLog(
          userId: doc.data()['userId'] as String,
          email: doc.data()['email'] as String,
          record: AttendanceRecordModel.fromMap(doc.data()).toEntity(),
        ),
    ];
    return LogsPageData(
      logs,
      page.docs.length > 30
          ? PageCursor(
              (docs.last.data()['checkInAt'] as Timestamp)
                  .toDate()
                  .toUtc()
                  .toIso8601String(),
              docs.last.id,
            )
          : null,
    );
  });
}
