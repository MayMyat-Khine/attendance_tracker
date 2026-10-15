import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';

sealed class RegisterState {
  const RegisterState();
}

final class RegisterCheckingSession extends RegisterState {
  const RegisterCheckingSession();
}

final class RegisterReady extends RegisterState {
  const RegisterReady({
    this.failure,
    this.isSubmitting = false,
    this.profileImage,
  });

  final Failure? failure;
  final bool isSubmitting;
  final ProfileImage? profileImage;
}

final class RegisterSucceeded extends RegisterState {
  const RegisterSucceeded(this.user);

  final AppUser user;
}
