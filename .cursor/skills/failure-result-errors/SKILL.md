---
name: failure-result-errors
description: >-
  Centralizes attendance_tracker errors as Failure and Result, including Network,
  Firebase, and Permission failures. Use when catching exceptions, mapping
  Firebase or platform errors, returning from repositories or use cases, or
  showing an error on screen.
---

# Failure and Result

Repositories and use cases return `Result<T>`. They do not throw for expected failures. Presentation never imports `FirebaseException`, `SocketException`, or plugin exceptions.

## Types

Put these in `lib/core/error/`.

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class FirebaseFailure extends Failure {
  const FirebaseFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final Failure failure;
}
```

`ValidationFailure` is for broken business rules (already checked in, empty email). The other failures come from `mapToFailure`.

## One mapper

`mapToFailure` lives in `lib/core/error/map_to_failure.dart` and is the only place that inspects exception types.

| Source | Failure |
| --- | --- |
| `SocketException`, `TimeoutException`, `HttpException`, `HandshakeException`, `http.ClientException`, Firebase `network-request-failed` or `unavailable` | `NetworkFailure` |
| Firebase `permission-denied`, `unauthenticated`, `user-disabled` | `PermissionFailure` with a user-safe message |
| Location or photo permission denied, location service off | `PermissionFailure` |
| GPS fix timed out (`LocationTimeoutException`) | `LocationFailure` (never `NetworkFailure`) |
| Firebase `invalid-email` | `ValidationFailure` |
| Other `FirebaseException` (auth and Firestore) | `FirebaseFailure` with a user-safe message |
| Anything else | `UnexpectedFailure` |

Auth copy for `FirebaseFailure`:

- `invalid-credential`, `wrong-password`, `user-not-found` → `Email or password is incorrect.`
- `email-already-in-use` → `An account already exists for that email.`
- `weak-password` → `Use a stronger password.`
- Any other code → `Request failed. Try again.`

Do not put `error.code` or `error.toString()` on screen.

## Where each layer handles errors

```dart
Future<Result<AttendanceLog>> checkIn(CheckInParams params) async {
  try {
    final log = await _remote.create(params);
    return Success(log);
  } catch (error) {
    return ResultFailure(mapToFailure(error));
  }
}
```

- Data sources throw. Repository implementations catch and return `ResultFailure`.
- Use cases return `ValidationFailure` directly. They do not catch plugin exceptions.
- Blocs `switch` on `Result` and emit a state that holds `Failure`.
- Pages show `failure.message`. One widget can render that message. Do not map exception types in the widget.

Offline check-in is a success path (`Success` of a pending log), not a `NetworkFailure`. Return `NetworkFailure` only when an online call was required and the network failed.

## Decisions worth stating in the reply

If you add a failure subtype, say which layer produces it and why the existing five types could not express it.
