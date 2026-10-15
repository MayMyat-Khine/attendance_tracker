import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';

Result<Unit> validateEmailAndPassword({
  required String email,
  required String password,
}) {
  if (email.trim().isEmpty) {
    return const ResultFailure(ValidationFailure('Email is required.'));
  }
  if (password.isEmpty) {
    return const ResultFailure(ValidationFailure('Password is required.'));
  }
  return const Success(Unit());
}

Result<Unit> validateUserRegistration({
  required String email,
  required String password,
  required String name,
  required String position,
  required String? department,
}) {
  final credentials = validateEmailAndPassword(
    email: email,
    password: password,
  );
  if (credentials is ResultFailure<Unit>) {
    return credentials;
  }
  if (name.trim().isEmpty) {
    return const ResultFailure(ValidationFailure('Name is required.'));
  }
  if (position.trim().isEmpty) {
    return const ResultFailure(ValidationFailure('Position is required.'));
  }
  if (department == null || department.trim().isEmpty) {
    return const ResultFailure(ValidationFailure('Department is required.'));
  }
  return const Success(Unit());
}
