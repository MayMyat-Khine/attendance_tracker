import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/auth_repository.dart';

final class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit>> call() => _repository.signOut();
}
