import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/auth_repository.dart';

final class SendPasswordReset {
  const SendPasswordReset(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit>> call(String email) {
    if (email.trim().isEmpty) {
      return Future.value(
        const ResultFailure(ValidationFailure('Email is required.')),
      );
    }

    return _repository.sendPasswordReset(email: email.trim());
  }
}
