import 'dart:async';
import 'dart:io';

import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/map_to_failure.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a socket error to NetworkFailure', () {
    final failure = mapToFailure(const SocketException('offline'));

    expect(failure, isA<NetworkFailure>());
    expect(failure.message, 'No internet connection.');
  });

  test('maps a timeout to NetworkFailure', () {
    final failure = mapToFailure(TimeoutException('timed out'));

    expect(failure, isA<NetworkFailure>());
  });

  test('maps Firebase network codes to NetworkFailure', () {
    for (final code in ['network-request-failed', 'unavailable']) {
      final failure = mapToFailure(
        FirebaseException(plugin: 'firebase_auth', code: code),
      );

      expect(failure, isA<NetworkFailure>(), reason: code);
    }
  });

  test('maps Firebase permission-denied to PermissionFailure', () {
    final failure = mapToFailure(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );

    expect(failure, isA<PermissionFailure>());
    expect(failure.message, 'You do not have access to this data.');
  });

  test('maps invalid credentials to a safe FirebaseFailure', () {
    for (final code in [
      'invalid-credential',
      'wrong-password',
      'user-not-found',
    ]) {
      final failure = mapToFailure(
        FirebaseException(plugin: 'firebase_auth', code: code),
      );

      expect(failure, isA<FirebaseFailure>(), reason: code);
      expect(failure.message, 'Email or password is incorrect.');
    }
  });

  test('maps email-already-in-use to a safe FirebaseFailure', () {
    final failure = mapToFailure(
      FirebaseException(plugin: 'firebase_auth', code: 'email-already-in-use'),
    );

    expect(failure, isA<FirebaseFailure>());
    expect(failure.message, 'An account already exists for that email.');
  });

  test('maps weak-password to a safe FirebaseFailure', () {
    final failure = mapToFailure(
      FirebaseException(plugin: 'firebase_auth', code: 'weak-password'),
    );

    expect(failure, isA<FirebaseFailure>());
    expect(failure.message, 'Use a stronger password.');
  });

  test('maps an unknown Firebase code to a generic FirebaseFailure', () {
    final failure = mapToFailure(
      FirebaseException(
        plugin: 'firebase_auth',
        code: 'internal',
        message: 'raw backend detail',
      ),
    );

    expect(failure, isA<FirebaseFailure>());
    expect(failure.message, 'Request failed. Try again.');
  });

  test('maps an unknown error to UnexpectedFailure', () {
    final failure = mapToFailure(StateError('unexpected'));

    expect(failure, isA<UnexpectedFailure>());
    expect(failure.message, 'Something went wrong.');
  });
}
