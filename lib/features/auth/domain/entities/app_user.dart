import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';

final class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.position,
    this.department,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? name;
  final String? position;
  final String? department;
}
