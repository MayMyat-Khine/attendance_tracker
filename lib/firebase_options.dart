import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:attendance_tracker/core/config/app_environment.dart';

/// Firebase settings come only from `--dart-define-from-file=config/<flavor>.json`.
/// Live flavors fail at startup when a required value is missing, so a build
/// can never fall back to another environment's project.
abstract final class DefaultFirebaseOptions {
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosBundleId = String.fromEnvironment('IOS_BUNDLE_ID');

  static const _localProjectId = 'demo-attendance-tracker';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform)) {
      throw UnsupportedError('This app supports Android and iOS only.');
    }
    if (AppConfig.environment == AppEnvironment.local) {
      return _local;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _require({
        'FIREBASE_PROJECT_ID': _projectId,
        'FIREBASE_SENDER_ID': _senderId,
        'FIREBASE_STORAGE_BUCKET': _storageBucket,
        'FIREBASE_IOS_API_KEY': _iosApiKey,
        'FIREBASE_IOS_APP_ID': _iosAppId,
        'IOS_BUNDLE_ID': _iosBundleId,
      });
      return const FirebaseOptions(
        apiKey: _iosApiKey,
        appId: _iosAppId,
        messagingSenderId: _senderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
      );
    }
    _require({
      'FIREBASE_PROJECT_ID': _projectId,
      'FIREBASE_SENDER_ID': _senderId,
      'FIREBASE_STORAGE_BUCKET': _storageBucket,
      'FIREBASE_ANDROID_API_KEY': _androidApiKey,
      'FIREBASE_ANDROID_APP_ID': _androidAppId,
    });
    return const FirebaseOptions(
      apiKey: _androidApiKey,
      appId: _androidAppId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
    );
  }

  static FirebaseOptions get _local => FirebaseOptions(
    apiKey: 'local-emulator-key',
    appId: defaultTargetPlatform == TargetPlatform.iOS
        ? '1:000000000000:ios:local'
        : '1:000000000000:android:local',
    messagingSenderId: '000000000000',
    projectId: _localProjectId,
    storageBucket: '$_localProjectId.appspot.com',
    iosBundleId: defaultTargetPlatform == TargetPlatform.iOS
        ? 'com.example.attendanceTracker'
        : null,
  );

  static void _require(Map<String, String> values) {
    final missing = [
      for (final entry in values.entries)
        if (entry.value.trim().isEmpty) entry.key,
    ];
    if (missing.isEmpty) return;
    throw StateError(
      'Missing Firebase config for ${AppConfig.environment.name}: '
      '${missing.join(', ')}. Run with '
      '--dart-define-from-file=config/${AppConfig.environment.name}.json.',
    );
  }
}
