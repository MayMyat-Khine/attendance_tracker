import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/validate_email_and_password.dart';

final class RegisterAccountParams {
  const RegisterAccountParams({
    required this.email,
    required this.password,
    this.name,
    this.position,
    this.department,
    this.profileImage,
  });

  final String email;
  final String password;
  final String? name;
  final String? position;
  final String? department;
  final ProfileImage? profileImage;
}

final class RegisterAccount {
  const RegisterAccount(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call(RegisterAccountParams params) {
    final validation = validateUserRegistration(
      email: params.email,
      password: params.password,
      name: params.name ?? '',
      position: params.position ?? '',
      department: params.department,
    );
    if (validation is ResultFailure<Unit>) {
      return Future.value(ResultFailure(validation.failure));
    }

    if (params.profileImage == null) {
      return Future.value(
        const ResultFailure(ValidationFailure('Choose a profile image.')),
      );
    }
    return _repository.register(
      email: params.email.trim(),
      password: params.password,
      role: UserRole.user,
      name: params.name?.trim(),
      position: params.position?.trim(),
      department: params.department?.trim(),
      profileImage: params.profileImage,
    );
  }
}
