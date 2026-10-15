import 'package:image_picker/image_picker.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/core/error/map_to_failure.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/profile_image_repository.dart';

final class ProfileImageRepositoryImpl implements ProfileImageRepository {
  @override
  Future<Result<ProfileImage?>> pick() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (file == null) return const Success(null);
      final bytes = await file.readAsBytes();
      final jpeg = bytes.length > 2 && bytes[0] == 255 && bytes[1] == 216;
      final png = bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80;
      if ((!jpeg && !png) || bytes.length > 5 * 1024 * 1024) {
        return const ResultFailure(
          ValidationFailure('Choose a JPEG or PNG image smaller than 5 MB.'),
        );
      }
      return Success(
        ProfileImage(
          bytes: bytes,
          contentType: jpeg ? 'image/jpeg' : 'image/png',
        ),
      );
    } catch (error) {
      return ResultFailure(mapToFailure(error));
    }
  }
}
