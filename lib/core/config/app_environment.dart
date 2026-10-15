enum AppEnvironment { local, staging, production }

abstract final class AppConfig {
  static AppEnvironment environment = AppEnvironment.production;
  static String get prefix =>
      environment == AppEnvironment.staging ? 'staging_' : '';
  static String get users => '${prefix}users';
  static String get attendance => '${prefix}attendance';
  static String get sessions => '${prefix}attendance_sessions';
  static String get profiles => '${prefix}profiles';
  static String get queueFile => 'attendance_v2_${environment.name}.json';
  static String get title => environment == AppEnvironment.production
      ? 'Attendance Tracker'
      : 'Attendance Tracker (${environment.name})';
}
