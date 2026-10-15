import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';

final class DashboardSummary {
  const DashboardSummary(this.totalUsers, this.checkIns, this.checkOuts);
  final int totalUsers;
  final int checkIns;
  final int checkOuts;
}

final class PageCursor {
  const PageCursor(this.value, this.id);
  final String value;
  final String id;
}

final class UsersPageData {
  const UsersPageData(this.users, this.next);
  final List<AppUser> users;
  final PageCursor? next;
}

final class AdminLog {
  const AdminLog({
    required this.userId,
    required this.email,
    required this.record,
  });
  final String userId;
  final String email;
  final AttendanceRecord record;
}

final class LogsPageData {
  const LogsPageData(this.logs, this.next);
  final List<AdminLog> logs;
  final PageCursor? next;
}
