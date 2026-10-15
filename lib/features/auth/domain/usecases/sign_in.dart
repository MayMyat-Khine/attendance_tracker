import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/validate_email_and_password.dart';

final class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;
}

final class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call(SignInParams params) async {
    final validation = validateEmailAndPassword(
      email: params.email,
      password: params.password,
    );
    if (validation is ResultFailure<Unit>) {
      return ResultFailure(validation.failure);
    }

    return _repository.signIn(
      email: params.email.trim(),
      password: params.password,
    );
  }
}
