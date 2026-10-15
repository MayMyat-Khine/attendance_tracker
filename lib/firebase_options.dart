import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:attendance_tracker/core/config/app_environment.dart';

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb &&
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform)) {
      throw UnsupportedError('This app supports Android, iOS, and web.');
    }
    final localWeb = kIsWeb && AppConfig.environment == AppEnvironment.local;
    const webApp = String.fromEnvironment('FIREBASE_WEB_APP_ID');
    const webKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
    if (kIsWeb && !localWeb && (webApp.isEmpty || webKey.isEmpty)) {
      throw StateError(
        'Configure FIREBASE_WEB_APP_ID and FIREBASE_WEB_API_KEY for live web builds. Use main_local.dart with emulators for local testing.',
      );
    }
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final local = AppConfig.environment == AppEnvironment.local;
    const project = String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'attendancetracker-b7a9b',
    );
    const sender = String.fromEnvironment(
      'FIREBASE_SENDER_ID',
      defaultValue: '114999346116',
    );
    const bucket = String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'attendancetracker-b7a9b.firebasestorage.app',
    );
    const androidKey = String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'AIzaSyAyfeyrJPe-HsME3dmNcyTX90zIIwbJvVo',
    );
    const iosKey = String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'AIzaSyBwqm1FqryWvFO3_1odupVDZrR4UAhKiGo',
    );
    const androidApp = String.fromEnvironment(
      'FIREBASE_ANDROID_APP_ID',
      defaultValue: '1:114999346116:android:6ca23002fdd2383926da91',
    );
    const iosApp = String.fromEnvironment(
      'FIREBASE_IOS_APP_ID',
      defaultValue: '1:114999346116:ios:1351c622f7f1247c26da91',
    );
    return FirebaseOptions(
      apiKey: local
          ? 'local-emulator-key'
          : kIsWeb
          ? webKey
          : (ios ? iosKey : androidKey),
      appId: kIsWeb
          ? (local ? '1:114999346116:web:local' : webApp)
          : ios
          ? iosApp
          : androidApp,
      authDomain: kIsWeb
          ? (local
                ? 'demo-attendance-tracker.firebaseapp.com'
                : const String.fromEnvironment(
                    'FIREBASE_AUTH_DOMAIN',
                    defaultValue: 'attendancetracker-b7a9b.firebaseapp.com',
                  ))
          : null,
      messagingSenderId: sender,
      projectId: local ? 'demo-attendance-tracker' : project,
      storageBucket: local ? 'demo-attendance-tracker.appspot.com' : bucket,
      iosBundleId: ios
          ? const String.fromEnvironment(
              'IOS_BUNDLE_ID',
              defaultValue: 'com.example.attendanceTracker',
            )
          : null,
    );
  }
}
