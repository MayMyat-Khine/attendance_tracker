import 'package:attendance_tracker/bootstrap.dart';
import 'package:attendance_tracker/core/config/app_environment.dart';
import 'package:flutter/services.dart' show appFlavor;

Future<void> main() => bootstrap(switch (appFlavor) {
  'local' => AppEnvironment.local,
  'staging' => AppEnvironment.staging,
  _ => AppEnvironment.production,
});
