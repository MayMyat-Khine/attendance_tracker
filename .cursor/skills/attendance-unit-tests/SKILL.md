---
name: attendance-unit-tests
description: >-
  Writes attendance_tracker unit tests for business rules, role scope, offline
  sync, and Failure mapping using hand-written fakes. Use when adding or changing
  use cases, check-in rules, history queries, error mapping, or files under test/.
---

# Unit tests

Test business logic in `test/`, mirroring `lib/features/.../domain`. Use `flutter_test` and hand-written fakes. Do not add `mockito`, `mocktail`, or `bloc_test`.

Prefer use-case tests over widget tests. Add a bloc test only when the bloc itself branches (stale search, keep-previous-data on failure).

## Fakes

```dart
class FakeAttendanceRepository implements AttendanceRepository {
  AttendanceLog? openSession;
  final List<AttendanceLog> created = [];
  Failure? writeFailure;

  @override
  Future<Result<AttendanceLog?>> getOpenSession(String userId) async {
    return Success(openSession);
  }

  @override
  Future<Result<AttendanceLog>> createLog(AttendanceLog log) async {
    final failure = writeFailure;
    if (failure != null) return ResultFailure(failure);
    created.add(log);
    return Success(log);
  }
}
```

Fakes record inputs and return scripted `Result` values. They contain no Firebase.

## Cases that must exist

| Use case | Assert |
| --- | --- |
| `CheckIn` with an open session | `ValidationFailure`, remote create not called |
| `CheckIn` with no open session | `Success`, stored timestamp is UTC, lat/lng copied from params |
| `CheckOut` with no open session | `ValidationFailure` |
| `CheckIn` while offline | queued log with `pendingSync: true`, remote create not called |
| `CheckIn` while offline and a check-in is already queued | `ValidationFailure` |
| `SyncPendingLogs` while online | writes in timestamp order, then the queue is empty |
| `SyncPendingLogs` when a write fails | failed item remains queued |
| User history | repository receives only the signed-in user id |
| Admin history | repository receives the selected user id and the UTC bounds of the local dates |
| `mapToFailure` | socket/timeout → `NetworkFailure`; Firebase `permission-denied` → `PermissionFailure`; other Firebase → `FirebaseFailure`; unknown → `UnexpectedFailure` |

Name tests as behavior: `'rejects a second check-in while a session is open'`.

Run the focused file after adding tests:

```bash
flutter test test/features/attendance/domain/usecases/check_in_test.dart
```

## Decisions worth stating in the reply

If a rule has no test, add the test in the same change. Mention the case you covered.
