import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:attendance_tracker/app.dart';
import 'package:attendance_tracker/firebase_options.dart';
import 'package:attendance_tracker/core/config/app_environment.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };
  try {
    await _initialize(environment);
  } catch (error, stack) {
    debugPrint('Startup failed: $error\n$stack');
    runApp(_StartupErrorApp(error: error, environment: environment));
    return;
  }
  runApp(const App());
}

Future<void> _initialize(AppEnvironment environment) async {
  if (appFlavor != null && appFlavor != environment.name) {
    throw StateError(
      'Build flavor and Dart entrypoint must use the same environment.',
    );
  }
  AppConfig.environment = environment;
  const overrideHost = String.fromEnvironment('EMULATOR_HOST');
  final host = overrideHost.isNotEmpty
      ? overrideHost
      : defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
  }
  if (environment == AppEnvironment.local) {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }
  await FirebaseAuth.instance.authStateChanges().first;
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error, required this.environment});

  final Object error;
  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final details = environment == AppEnvironment.production
        ? null
        : error is StateError
        ? (error as StateError).message
        : '$error';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'The app could not start. Check your connection and '
                    'reopen the app.',
                    textAlign: TextAlign.center,
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 12),
                    Text(details, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
