import 'package:attendance_tracker/features/attendance/domain/entities/attendance_action.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_day.dart';

final class UserHistory {
  const UserHistory({
    required this.days,
    required this.savedDays,
    required this.action,
    required this.today,
  });

  final List<AttendanceDay> days;
  final List<AttendanceDay> savedDays;
  final AttendanceAction action;
  final String today;
}
