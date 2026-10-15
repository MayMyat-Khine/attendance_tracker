import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required UserRole role,
    String? name,
    String? position,
    String? department,
  });

  Future<Result<Unit>> sendPasswordReset({required String email});

  Future<Result<AppUser?>> currentUser();

  Future<Result<Unit>> signOut();
}
