import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/send_password_reset.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SendPasswordReset sendPasswordReset;

  setUp(() {
    repository = FakeAuthRepository();
    sendPasswordReset = SendPasswordReset(repository);
  });

  test('rejects an empty email without calling the repository', () async {
    final result = await sendPasswordReset('   ');

    final failure = (result as ResultFailure<Unit>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'Email is required.');
    expect(repository.resetCalls, 0);
  });

  test('sends a reset email for the trimmed address', () async {
    final result = await sendPasswordReset(' user@example.com ');

    expect(result, isA<Success<Unit>>());
    expect(repository.resetCalls, 1);
    expect(repository.lastResetEmail, 'user@example.com');
  });
}
