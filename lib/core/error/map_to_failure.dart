import 'dart:async';
import 'dart:io';

import 'package:attendance_tracker/core/error/failure.dart';
import 'package:firebase_core/firebase_core.dart';

Failure mapToFailure(Object error) {
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
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => const FirebaseFailure(
      'Email or password is incorrect.',
    ),
    'email-already-in-use' => const FirebaseFailure(
      'An account already exists for that email.',
    ),
    'weak-password' => const FirebaseFailure('Use a stronger password.'),
    _ => const FirebaseFailure('Request failed. Try again.'),
  };
}
