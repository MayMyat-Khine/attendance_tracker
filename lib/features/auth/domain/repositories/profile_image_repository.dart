import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';

abstract class ProfileImageRepository {
  Future<Result<ProfileImage?>> pick();
}
