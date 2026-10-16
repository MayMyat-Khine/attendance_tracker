import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

Failure mapToFailure(Object error) {
  if (error is OperationFailureException) return error.failure;
  if (error is AccessDeniedException) {
    return const PermissionFailure('You do not have access to this data.');
  }
  if (error is PlatformException &&
      {
        'photo_access_denied',
        'camera_access_denied',
        'photo_access_restricted',
      }.contains(error.code)) {
    return const PermissionFailure('Allow photo access in device settings.');
  }
  if (error is LocationPermissionException) {
    return const PermissionFailure(
      'Location permission is required to check in or out.',
    );
  }
  if (error is LocationServiceException) {
    return const PermissionFailure(
      'Turn on location services to check in or out.',
    );
  }
  if (error is LocationTimeoutException) {
    return const LocationFailure();
  }
  if (error is AttendanceConflictException) {
    return ValidationFailure(error.message);
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException ||
      error is HandshakeException ||
      error is http.ClientException) {
    return const NetworkFailure();
  }
  if (error is FirebaseException) {
    return _fromFirebase(error);
  }
  return const UnexpectedFailure();
}

Failure _fromFirebase(FirebaseException error) {
  return switch (error.code) {
    'network-request-failed' ||
    'unavailable' ||
    'deadline-exceeded' => const NetworkFailure(),
    'unauthorized' || 'permission-denied' => const PermissionFailure(
      'You do not have access to this data.',
    ),
    'unauthenticated' || 'requires-recent-login' => const PermissionFailure(
      'Your session has expired. Sign in again.',
    ),
    'invalid-credential' ||
    'invalid-login-credentials' ||
    'wrong-password' ||
    'user-not-found' => const FirebaseFailure(
      'Email or password is incorrect.',
    ),
    'invalid-email' => const ValidationFailure('Enter a valid email address.'),
    'user-disabled' => const PermissionFailure(
      'This account has been disabled. Contact your administrator.',
    ),
    'operation-not-allowed' => const FirebaseFailure(
      'Email sign-in is not enabled for this project.',
    ),
    'email-already-in-use' => const FirebaseFailure(
      'An account already exists for that email.',
    ),
    'weak-password' => const FirebaseFailure('Use a stronger password.'),
    'failed-precondition' => const FirebaseFailure(
      'Database setup is incomplete. Ask your administrator to deploy the indexes.',
    ),
    'bucket-not-found' || 'project-not-found' => const FirebaseFailure(
      'Profile storage is not configured. Contact your administrator.',
    ),
    'too-many-requests' || 'resource-exhausted' => const FirebaseFailure(
      'Too many attempts. Please try again later.',
    ),
    'aborted' => const FirebaseFailure(
      'The data changed while saving. Try again.',
    ),
    'not-found' => const FirebaseFailure('The requested data was not found.'),
    'missing-role' => const FirebaseFailure('This account has no role.'),
    _ => const FirebaseFailure('Request failed. Try again.'),
  };
}
