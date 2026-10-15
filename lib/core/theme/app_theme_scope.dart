import 'package:flutter/material.dart';

class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    required this.toggle,
    required super.child,
    super.key,
  });

  final VoidCallback toggle;

  static AppThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope is missing above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) =>
      toggle != oldWidget.toggle;
}

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Light theme' : 'Dark theme',
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: AppThemeScope.of(context).toggle,
    );
  }
}
