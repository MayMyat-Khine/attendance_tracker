import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_in.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SignIn signIn;

  setUp(() {
    repository = FakeAuthRepository();
    signIn = SignIn(repository);
  });

  test('rejects an empty email without calling the repository', () async {
    final result = await signIn(
      const SignInParams(email: '   ', password: 'secret'),
    );

    final failure = (result as ResultFailure<AppUser>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'Email is required.');
    expect(repository.signInCalls, 0);
  });

  test('rejects an empty password without calling the repository', () async {
    final result = await signIn(
      const SignInParams(email: 'user@example.com', password: ''),
    );

    final failure = (result as ResultFailure<AppUser>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'Password is required.');
    expect(repository.signInCalls, 0);
  });

  test('returns the stored admin role for role-based routing', () async {
    repository.signedInUser = const AppUser(
      id: 'admin',
      email: 'admin@example.com',
      role: UserRole.admin,
    );
    final result = await signIn(
      const SignInParams(email: ' admin@example.com ', password: 'secret'),
    );
    expect((result as Success<AppUser>).value.role, UserRole.admin);
    expect(repository.lastEmail, 'admin@example.com');
  });

  test('returns the user when the stored role matches the screen', () async {
    repository.signedInUser = const AppUser(
      id: '1',
      email: 'user@example.com',
      role: UserRole.user,
    );

    final result = await signIn(
      const SignInParams(email: 'user@example.com', password: 'secret'),
    );

    expect(result, isA<Success<AppUser>>());
    expect((result as Success<AppUser>).value.role, UserRole.user);
    expect(repository.signOutCalls, 0);
  });
}
