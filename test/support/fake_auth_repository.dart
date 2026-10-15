import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/auth_repository.dart';

final class FakeAuthRepository implements AuthRepository {
  AppUser? signedInUser;
  AppUser? current;
  Failure? signInFailure;
  int signInCalls = 0;
  int registerCalls = 0;
  int signOutCalls = 0;
  int resetCalls = 0;
  String? lastEmail;
  String? lastPassword;
  UserRole? lastRole;
  String? lastName;
  String? lastPosition;
  String? lastDepartment;
  String? lastResetEmail;

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    final failure = signInFailure;
    if (failure != null) {
      return ResultFailure(failure);
    }
    final user = signedInUser;
    if (user == null) {
      return const ResultFailure(FirebaseFailure('Account profile is missing.'));
    }
    return Success(user);
  }

  @override
  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required UserRole role,
    String? name,
    String? position,
    String? department,
  }) async {
    registerCalls++;
    lastEmail = email;
    lastPassword = password;
    lastRole = role;
    lastName = name;
    lastPosition = position;
    lastDepartment = department;
    return Success(
      AppUser(
        id: 'user-1',
        email: email,
        role: role,
        name: name,
        position: position,
        department: department,
      ),
    );
  }

  @override
  Future<Result<Unit>> sendPasswordReset({required String email}) async {
    resetCalls++;
    lastResetEmail = email;
    return const Success(Unit());
  }

  @override
  Future<Result<AppUser?>> currentUser() async => Success(current);

  @override
  Future<Result<Unit>> signOut() async {
    signOutCalls++;
    return const Success(Unit());
  }
}
