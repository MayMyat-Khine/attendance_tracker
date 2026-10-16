import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:attendance_tracker/core/config/app_environment.dart';
import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';

/// Uploads through an unsigned Cloudinary upload preset. The API key and
/// secret must never ship in the app; restrict formats and size on the preset.
final class CloudinaryProfileUploader {
  const CloudinaryProfileUploader();

  static const _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  static const _uploadFailed = UnexpectedFailure(
    'Could not upload the profile image.',
  );

  Future<String> upload({
    required String uid,
    required ProfileImage image,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw const OperationFailureException(
        UnexpectedFailure('Profile photo upload is not configured.'),
      );
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
    );
    request.fields.addAll({
      'upload_preset': _uploadPreset,
      'folder': '${AppConfig.environment.name}/profiles',
      'tags': uid,
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        image.bytes,
        filename: image.contentType == 'image/png'
            ? 'avatar.png'
            : 'avatar.jpg',
      ),
    );

    final response = await request.send().timeout(const Duration(seconds: 30));
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw const OperationFailureException(_uploadFailed);
    }
    final decoded = jsonDecode(body);
    final url = decoded is Map<String, dynamic> ? decoded['secure_url'] : null;
    if (url is! String || url.isEmpty) {
      throw const OperationFailureException(_uploadFailed);
    }
    return url;
  }
}
