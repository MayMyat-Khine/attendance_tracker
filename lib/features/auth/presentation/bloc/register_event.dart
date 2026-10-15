sealed class RegisterEvent {
  const RegisterEvent();
}

final class RegisterStarted extends RegisterEvent {
  const RegisterStarted();
}

final class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted({
    required this.email,
    required this.password,
    this.name,
    this.position,
    this.department,
  });

  final String email;
  final String password;
  final String? name;
  final String? position;
  final String? department;
}

final class ProfileImageRequested extends RegisterEvent {
  const ProfileImageRequested();
}
