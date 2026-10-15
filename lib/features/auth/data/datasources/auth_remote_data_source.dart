import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:attendance_tracker/features/auth/data/models/app_user_model.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';

abstract class AuthRemoteDataSource {
  Future<AppUserModel?> signIn({
    required String email,
    required String password,
  });

  Future<AppUserModel> register({
    required String email,
    required String password,
    required UserRole role,
    String? name,
    String? position,
    String? department,
    ProfileImage? profileImage,
  });

  Future<void> sendPasswordReset({required String email});

  Future<AppUserModel?> currentUser();

  Future<void> signOut();
}
