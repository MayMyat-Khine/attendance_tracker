import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class PhotoPermissionDataSource {
  static const _channel = MethodChannel('attendance_tracker/photo_permission');

  Future<void> request() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final granted = await _channel.invokeMethod<bool>('request');
    if (granted != true) {
      throw PlatformException(code: 'photo_access_denied');
    }
  }
}
