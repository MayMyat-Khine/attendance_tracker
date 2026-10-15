import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/map_to_failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/unit.dart';
import 'package:attendance_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  static const _missingProfile = FirebaseFailure('Account profile is missing.');

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _remote.signIn(email: email, password: password);
      if (model == null) {
        return const ResultFailure(_missingProfile);
      }
      return Success(model.toEntity());
    } catch (error) {
      await _signOutQuietly();
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<AppUser>> register({
    required String email,
    required String password,
    required UserRole role,
    String? name,
    String? position,
    String? department,
    ProfileImage? profileImage,
  }) async {
    if (role != UserRole.user) {
      return const ResultFailure(
        PermissionFailure('Admin roles are assigned in Firebase.'),
      );
    }
    try {
      final model = await _remote.register(
        email: email,
        password: password,
        role: role,
        name: name,
        position: position,
        department: department,
        profileImage: profileImage,
      );
      return Success(model.toEntity());
    } catch (error) {
      await _signOutQuietly();
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<Unit>> sendPasswordReset({required String email}) async {
    try {
      await _remote.sendPasswordReset(email: email);
      return const Success(Unit());
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<AppUser?>> currentUser() async {
    try {
      final model = await _remote.currentUser();
      return Success(model?.toEntity());
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  @override
  Future<Result<Unit>> signOut() async {
    try {
      await _remote.signOut();
      return const Success(Unit());
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }

  Future<void> _signOutQuietly() async {
    try {
      await _remote.signOut();
    } on Object {
      // Keep the original registration failure if cleanup also fails.
    }
  }
}
