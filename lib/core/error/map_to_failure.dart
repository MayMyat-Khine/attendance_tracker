import 'dart:async';
import 'dart:io';

import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:firebase_core/firebase_core.dart';

Failure mapToFailure(Object error) {
  if (error is LocationPermissionException) {
    return const PermissionFailure(
      'Location permission is required to check in.',
    );
  }
  if (error is LocationServiceException) {
    return const PermissionFailure('Turn on location services to check in.');
  }
  if (error is AttendanceConflictException) {
    return ValidationFailure(error.message);
  }
  if (error is SocketException || error is TimeoutException) {
    return const NetworkFailure();
  }
  if (error is FirebaseException) {
    return _fromFirebase(error);
  }
  return const UnexpectedFailure();
}

Failure _fromFirebase(FirebaseException error) {
  return switch (error.code) {
    'network-request-failed' || 'unavailable' => const NetworkFailure(),
    'permission-denied' => const PermissionFailure(
      'You do not have access to this data.',
    ),
    'invalid-credential' || 'wrong-password' || 'user-not-found' =>
      const FirebaseFailure('Email or password is incorrect.'),
    'email-already-in-use' => const FirebaseFailure(
      'An account already exists for that email.',
    ),
    'weak-password' => const FirebaseFailure('Use a stronger password.'),
    'missing-role' => const FirebaseFailure('This account has no role.'),
    _ => const FirebaseFailure('Request failed. Try again.'),
  };
}
