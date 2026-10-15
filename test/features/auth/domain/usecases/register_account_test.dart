import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/register_account.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late RegisterAccount registerAccount;

  setUp(() {
    repository = FakeAuthRepository();
    registerAccount = RegisterAccount(repository);
  });

  test('rejects an empty email without calling the repository', () async {
    final result = await registerAccount(
      const RegisterAccountParams(
        email: '',
        password: 'secret',
        role: UserRole.user,
        name: 'Ada',
        position: 'Engineer',
        department: 'IT',
      ),
    );

    final failure = (result as ResultFailure<AppUser>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(repository.registerCalls, 0);
  });

  test('rejects an empty password without calling the repository', () async {
    final result = await registerAccount(
      const RegisterAccountParams(
        email: 'user@example.com',
        password: '',
        role: UserRole.admin,
      ),
    );

    final failure = (result as ResultFailure<AppUser>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'Password is required.');
    expect(repository.registerCalls, 0);
  });

  test('rejects a user registration without name', () async {
    final result = await registerAccount(
      const RegisterAccountParams(
        email: 'user@example.com',
        password: 'secret',
        role: UserRole.user,
        name: '  ',
        position: 'Engineer',
        department: 'IT',
      ),
    );

    final failure = (result as ResultFailure<AppUser>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'Name is required.');
    expect(repository.registerCalls, 0);
  });

  test('rejects a user registration without department', () async {
    final result = await registerAccount(
      const RegisterAccountParams(
        email: 'user@example.com',
        password: 'secret',
        role: UserRole.user,
        name: 'Ada',
        position: 'Engineer',
      ),
    );

    final failure = (result as ResultFailure<AppUser>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'Department is required.');
    expect(repository.registerCalls, 0);
  });

  test('registers a user with profile fields', () async {
    final result = await registerAccount(
      const RegisterAccountParams(
        email: ' user@example.com ',
        password: 'secret',
        role: UserRole.user,
        name: ' Ada Lovelace ',
        position: ' Engineer ',
        department: 'IT',
      ),
    );

    final user = (result as Success<AppUser>).value;
    expect(user.role, UserRole.user);
    expect(user.name, 'Ada Lovelace');
    expect(user.position, 'Engineer');
    expect(user.department, 'IT');
    expect(repository.lastRole, UserRole.user);
    expect(repository.lastEmail, 'user@example.com');
    expect(repository.lastName, 'Ada Lovelace');
    expect(repository.lastPosition, 'Engineer');
    expect(repository.lastDepartment, 'IT');
  });

  test('registers an admin with the admin role', () async {
    final result = await registerAccount(
      const RegisterAccountParams(
        email: 'admin@example.com',
        password: 'secret',
        role: UserRole.admin,
      ),
    );

    expect((result as Success<AppUser>).value.role, UserRole.admin);
    expect(repository.lastRole, UserRole.admin);
    expect(repository.lastName, isNull);
  });
}
