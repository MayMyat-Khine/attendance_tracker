import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';

sealed class LoginState {
  const LoginState();
}

final class LoginCheckingSession extends LoginState {
  const LoginCheckingSession();
}

final class LoginReady extends LoginState {
  const LoginReady({
    this.failure,
    this.isSubmitting = false,
    this.passwordResetSent = false,
  });

  final Failure? failure;
  final bool isSubmitting;
  final bool passwordResetSent;
}

final class LoginSucceeded extends LoginState {
  const LoginSucceeded(this.user);

  final AppUser user;
}
