import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:attendance_tracker/core/error/app_exception.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';

final class CloudinaryProfileUploader {
  const CloudinaryProfileUploader();

  static const _asset = 'config/cloudinary.local.json';

  Future<String> upload({
    required String uid,
    required ProfileImage image,
  }) async {
    final config = await _config();
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final publicId = 'profiles/$uid';
    final payload =
        'overwrite=true&public_id=$publicId&timestamp=$timestamp${config.apiSecret}';
    final signature = sha1.convert(utf8.encode(payload)).toString();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.cloudinary.com/v1_1/${config.cloudName}/image/upload',
      ),
    );
    request.fields.addAll({
      'api_key': config.apiKey,
      'timestamp': '$timestamp',
      'signature': signature,
      'public_id': publicId,
      'overwrite': 'true',
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        image.bytes,
        filename: image.contentType == 'image/png' ? 'avatar.png' : 'avatar.jpg',
      ),
    );

    final http.StreamedResponse response;
    try {
      response = await request.send().timeout(const Duration(seconds: 30));
    } on http.ClientException {
      throw const OperationFailureException(NetworkFailure());
    }
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw const OperationFailureException(
        FirebaseFailure('Could not upload the profile image.'),
      );
    }
    final decoded = jsonDecode(body);
    final url = decoded is Map<String, dynamic> ? decoded['secure_url'] : null;
    if (url is! String || url.isEmpty) {
      throw const OperationFailureException(
        FirebaseFailure('Could not upload the profile image.'),
      );
    }
    return url;
  }

  Future<_CloudinaryConfig> _config() async {
    final String raw;
    try {
      raw = await rootBundle.loadString(_asset);
    } on Object {
      throw const OperationFailureException(
        FirebaseFailure('Cloudinary is not configured.'),
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const OperationFailureException(
        FirebaseFailure('Cloudinary is not configured.'),
      );
    }
    final cloudName = decoded['cloudName'];
    final apiKey = decoded['apiKey'];
    final apiSecret = decoded['apiSecret'];
    if (cloudName is! String ||
        cloudName.isEmpty ||
        apiKey is! String ||
        apiKey.isEmpty ||
        apiSecret is! String ||
        apiSecret.isEmpty) {
      throw const OperationFailureException(
        FirebaseFailure('Cloudinary is not configured.'),
      );
    }
    return _CloudinaryConfig(
      cloudName: cloudName,
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
  }
}

final class _CloudinaryConfig {
  const _CloudinaryConfig({
    required this.cloudName,
    required this.apiKey,
    required this.apiSecret,
  });

  final String cloudName;
  final String apiKey;
  final String apiSecret;
}
