import 'package:flutter/material.dart';

import 'package:attendance_tracker/app_dependencies.dart';
import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  Widget build(BuildContext context) {
    final resolved = dependencies ?? AppDependencies.firebase();

    return MaterialApp(
      title: 'Attendance Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRouter.login,
      onGenerateRoute: (settings) {
        return AppRouter.onGenerateRoute(settings, resolved);
      },
    );
  }
}
