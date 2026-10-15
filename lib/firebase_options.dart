import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Firebase is not configured for this platform.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyfeyrJPe-HsME3dmNcyTX90zIIwbJvVo',
    appId: '1:114999346116:android:6ca23002fdd2383926da91',
    messagingSenderId: '114999346116',
    projectId: 'attendancetracker-b7a9b',
    storageBucket: 'attendancetracker-b7a9b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBwqm1FqryWvFO3_1odupVDZrR4UAhKiGo',
    appId: '1:114999346116:ios:1351c622f7f1247c26da91',
    messagingSenderId: '114999346116',
    projectId: 'attendancetracker-b7a9b',
    storageBucket: 'attendancetracker-b7a9b.firebasestorage.app',
    iosBundleId: 'com.example.attendanceTracker',
  );
}
