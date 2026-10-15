import 'package:attendance_tracker/core/config/app_environment.dart';
import 'package:flutter/material.dart';

import 'package:attendance_tracker/app_dependencies.dart';
import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppDependencies resolved =
      widget.dependencies ?? AppDependencies.firebase();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.title,
      debugShowCheckedModeBanner: false,
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
