import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/check_in.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/check_out.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/get_user_history.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/sync_pending_logs.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import '../../support/attendance_fakes.dart';
import '../../support/fake_auth_repository.dart';

void main() {
  late FakeNetwork network;
  late FakeAttendanceRemote remote;
  late FakeAuthRepository auth;
  late MemoryAttendance disk;
  late AttendanceRepositoryImpl repo;
  const location = GeoLocation(latitude: 16.8661, longitude: 96.1951);
  const email = 'user@example.com';
  setUp(() {
    network = FakeNetwork();
    remote = FakeAttendanceRemote();
    disk = MemoryAttendance();
    auth = FakeAuthRepository()
      ..current = const AppUser(
        id: 'user-1',
        email: email,
        role: UserRole.user,
      );
    repo = AttendanceRepositoryImpl(
      remote: remote,
      store: disk.createStore(),
      networkInfo: network,
      authRepository: auth,
    );
  });
  Future<Result<AttendanceRecord>> checkIn() =>
      CheckIn(repo)(const CheckInParams(email: email, location: location));
  test('queues offline check-in with UTC event time and location', () async {
    final result = await checkIn() as Success<AttendanceRecord>;
    expect(result.value.pendingSync, isTrue);
    expect(result.value.checkInAt!.isUtc, isTrue);
    expect(result.value.latitude, location.latitude);
    expect(remote.uploaded, isEmpty);
    expect(await disk.createStore().readPending(), hasLength(1));
  });
  test(
    'rejects a second offline check-in without changing the queue',
    () async {
      await checkIn();
      expect(
        (await checkIn() as ResultFailure).failure,
        isA<ValidationFailure>(),
      );
      expect(await disk.createStore().readPending(), hasLength(1));
    },
  );
  test('rejects checkout without an open session', () async {
    final result = await CheckOut(repo)(email: email, location: location);
    expect((result as ResultFailure).failure, isA<ValidationFailure>());
    expect(await disk.createStore().readPending(), isEmpty);
  });
  test(
    'allows one pair per day and retains fresh checkout coordinates',
    () async {
      await checkIn();
      const checkoutLocation = GeoLocation(latitude: 17, longitude: 97);
      final out =
          await CheckOut(repo)(email: email, location: checkoutLocation)
              as Success<AttendanceRecord>;
      expect(out.value.isComplete, isTrue);
      expect(out.value.checkOutLatitude, 17);
      expect(out.value.checkOutAt!.isUtc, isTrue);
      expect(
        (await checkIn() as ResultFailure).failure,
        isA<ValidationFailure>(),
      );
      expect(await disk.createStore().readPending(), hasLength(2));
    },
  );
  test(
    'restores pending history from a new store and repository instance',
    () async {
      await checkIn();
      final restored = AttendanceRepositoryImpl(
        remote: remote,
        store: disk.createStore(),
        networkInfo: network,
        authRepository: auth,
      );
      final result = await GetUserHistory(restored)(email: email);
      expect((result as Success).value.savedDays.single.pendingSync, isTrue);
    },
  );
  test(
    'syncs queued actions in timestamp order and removes uploaded items',
    () async {
      await checkIn();
      await CheckOut(repo)(email: email, location: location);
      final pending = await disk.createStore().readPending();
      network.online = true;
      expect(await SyncPendingLogs(repo)(), isA<Success>());
      expect(remote.uploaded, pending.map((op) => op.id).toList());
      expect(await disk.createStore().readPending(), isEmpty);
      expect(remote.records.single.checkOutAt!.isUtc, isTrue);
    },
  );
  test('retains a failed upload and reports its network failure', () async {
    await checkIn();
    network.online = true;
    remote.uploadError = TimeoutException('offline');
    expect(
      (await SyncPendingLogs(repo)() as ResultFailure).failure,
      isA<NetworkFailure>(),
    );
    expect(await disk.createStore().readPending(), hasLength(1));
  });
  test(
    'returns queued success if the network fails after saving an online action',
    () async {
      network.online = true;
      remote.uploadError = TimeoutException('offline');
      expect(await checkIn(), isA<Success<AttendanceRecord>>());
      expect(await disk.createStore().readPending(), hasLength(1));
    },
  );
  test(
    "does not sync another signed-in employee's pending operations",
    () async {
      await checkIn();
      network.online = true;
      remote.uid = 'user-2';
      remote.email = 'other@example.com';
      auth.current = const AppUser(
        id: 'user-2',
        email: 'other@example.com',
        role: UserRole.user,
      );
      await SyncPendingLogs(repo)();
      expect(remote.uploaded, isEmpty);
      expect(await disk.createStore().readPending(), hasLength(1));
    },
  );
  test('rejects cross-user history reads and admin employee writes', () async {
    expect(
      (await repo.getHistory(email: 'other@example.com') as ResultFailure)
          .failure,
      isA<PermissionFailure>(),
    );
    auth.current = const AppUser(
      id: 'user-1',
      email: email,
      role: UserRole.admin,
    );
    expect(
      (await repo.checkIn(email: email, location: location) as ResultFailure)
          .failure,
      isA<PermissionFailure>(),
    );
  });
}
