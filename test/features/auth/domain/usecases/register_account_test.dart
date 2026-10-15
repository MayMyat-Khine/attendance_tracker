import 'dart:typed_data';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
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
      const RegisterAccountParams(email: 'user@example.com', password: ''),
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
      RegisterAccountParams(
        email: ' user@example.com ',
        password: 'secret',
        profileImage: ProfileImage(
          bytes: Uint8List.fromList([255, 216, 255]),
          contentType: 'image/jpeg',
        ),
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

  test('rejects registration without a profile image', () async {
    final result = await registerAccount(
      const RegisterAccountParams(
        email: 'user@example.com',
        password: 'secret',
        name: 'Ada',
        position: 'Engineer',
        department: 'IT',
      ),
    );
    expect(
      (result as ResultFailure<AppUser>).failure,
      isA<ValidationFailure>(),
    );
    expect(repository.registerCalls, 0);
  });
}
