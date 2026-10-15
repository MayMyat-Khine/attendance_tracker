import 'package:attendance_tracker/core/config/app_environment.dart';
import 'package:flutter/material.dart';

import 'package:attendance_tracker/app_dependencies.dart';
import 'package:attendance_tracker/core/router/app_router.dart';
import 'package:attendance_tracker/core/theme/app_theme.dart';
import 'package:attendance_tracker/core/theme/app_theme_scope.dart';

class App extends StatefulWidget {
  const App({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppDependencies resolved =
      widget.dependencies ?? AppDependencies.firebase();
  ThemeMode _themeMode =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark
      ? ThemeMode.dark
      : ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      toggle: _toggleTheme,
      child: MaterialApp(
        title: AppConfig.title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        initialRoute: AppRouter.login,
        onGenerateRoute: (settings) {
          return AppRouter.onGenerateRoute(settings, resolved);
        },
      ),
    );
  }
}
