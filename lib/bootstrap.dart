import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:attendance_tracker/app.dart';
import 'package:attendance_tracker/platform/firebase_web_setup.dart';
import 'package:attendance_tracker/firebase_options.dart';
import 'package:attendance_tracker/core/config/app_environment.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (appFlavor != null && appFlavor != environment.name) {
    throw StateError(
      'Build flavor and Dart entrypoint must use the same environment.',
    );
  }
  AppConfig.environment = environment;
  const overrideHost = String.fromEnvironment('EMULATOR_HOST');
  final host = overrideHost.isNotEmpty
      ? overrideHost
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  final options = DefaultFirebaseOptions.currentPlatform;
  if (kIsWeb && environment == AppEnvironment.local) {
    await prepareLocalWebFirebase(options, host);
  }
  try {
    await Firebase.initializeApp(options: options);
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
  }
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      webPersistentTabManager: WebPersistentMultipleTabManager(),
    );
  }
  if (environment == AppEnvironment.local) {
    if (!kIsWeb) await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }
  // Web restores persisted credentials asynchronously; route guards need the initial auth state.
  await FirebaseAuth.instance.authStateChanges().first;
  runApp(const App());
}
