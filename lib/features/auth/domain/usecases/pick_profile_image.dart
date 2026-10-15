import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/profile_image_repository.dart';

final class PickProfileImage {
  const PickProfileImage(this._repository);
  final ProfileImageRepository _repository;
  Future<Result<ProfileImage?>> call() => _repository.pick();
}
