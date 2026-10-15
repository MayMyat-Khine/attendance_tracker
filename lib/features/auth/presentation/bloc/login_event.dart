sealed class LoginEvent {
  const LoginEvent();
}

final class LoginStarted extends LoginEvent {
  const LoginStarted();
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

final class ForgotPasswordRequested extends LoginEvent {
  const ForgotPasswordRequested({required this.email});

  final String email;
}
