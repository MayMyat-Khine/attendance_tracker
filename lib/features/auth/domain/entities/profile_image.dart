import 'dart:typed_data';

final class ProfileImage {
  const ProfileImage({required this.bytes, required this.contentType});
  final Uint8List bytes;
  final String contentType;
}
