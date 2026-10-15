import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/auth_repository.dart';

final class GetSignedInUser {
  const GetSignedInUser(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser?>> call() => _repository.currentUser();
}
