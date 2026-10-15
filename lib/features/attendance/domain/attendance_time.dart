import 'package:attendance_tracker/features/attendance/domain/entities/attendance_action.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_day.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/user_history.dart';

const checkOutBeforeCheckInMessage = 'Check out before checking in again.';

const checkInBeforeCheckOutMessage = 'Check in before checking out.';

const alreadyCheckedOutMessage = 'Already checked out for today.';

String formatAttendanceDate(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

const _monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String displayAttendanceDate(String stored) {
  final parts = stored.split('-');
  if (parts.length != 3) {
    return stored;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null ||
      month == null ||
      day == null ||
      month < 1 ||
      month > 12) {
    return stored;
  }
  return '${_monthLabels[month - 1]} $day $year';
}

String displayLocalDate(DateTime value) {
  return displayAttendanceDate(formatAttendanceDate(value));
}

String displayLocation(String coordinates) => 'Check in Location $coordinates';

String formatAttendanceTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool isAbsentStatus({required String checkIn, required String checkOut}) =>
    checkIn.trim().isEmpty && checkOut.trim().isEmpty;

String displayAttendanceTime(String stored) {
  final value = stored.trim();
  if (value.isEmpty) {
    return '-';
  }
  final parts = value.split(':');
  if (parts.length != 2) {
    return value;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return value;
  }
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

AttendanceRecord? openRecord(List<AttendanceRecord> records) {
  for (final record in records) {
    if (record.isOpen) {
      return record;
    }
  }
  return null;
}

bool isDayComplete(List<AttendanceRecord> records, String date) {
  for (final record in records) {
    if (record.date == date && record.isComplete) {
      return true;
    }
  }
  return false;
}

AttendanceAction actionFor(List<AttendanceRecord> records, String today) {
  if (openRecord(records) != null) {
    return AttendanceAction.checkOut;
  }
  if (isDayComplete(records, today)) {
    return AttendanceAction.completed;
  }
  return AttendanceAction.checkIn;
}

UserHistory buildCurrentMonthHistory({
  required List<AttendanceRecord> records,
  required DateTime now,
}) {
  final local = now.toLocal();
  final today = DateTime(local.year, local.month, local.day);
  final first = DateTime(local.year, local.month, 1);
  final todayKey = formatAttendanceDate(today);
  final days = <AttendanceDay>[];

  for (
    var cursor = today;
    !cursor.isBefore(first);
    cursor = cursor.subtract(const Duration(days: 1))
  ) {
    final date = formatAttendanceDate(cursor);
    AttendanceRecord? match;
    for (final record in records) {
      if (record.date == date) {
        match = record;
        break;
      }
    }
    if (match == null || match.checkIn.isEmpty) {
      days.add(AttendanceDay(date: date, isAbsent: true));
      continue;
    }
    days.add(
      AttendanceDay(
        date: date,
        isAbsent: false,
        checkInAt: match.checkInAt,
        checkOutAt: match.checkOutAt,
        location: _coordinates(match.latitude, match.longitude),
        checkOutLocation: _coordinates(
          match.checkOutLatitude,
          match.checkOutLongitude,
        ),
        checkIn: match.checkIn,
        checkOut: match.checkOut,
        pendingSync: match.pendingSync,
      ),
    );
  }

  return UserHistory(
    days: days,
    savedDays: savedHistoryDays(records),
    action: actionFor(records, todayKey),
    today: todayKey,
  );
}

List<AttendanceDay> savedHistoryDays(List<AttendanceRecord> records) {
  final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
  return [
    for (final record in sorted)
      if (record.checkIn.isNotEmpty)
        AttendanceDay(
          date: record.date,
          isAbsent: false,
          checkInAt: record.checkInAt,
          checkOutAt: record.checkOutAt,
          location: _coordinates(record.latitude, record.longitude),
          checkOutLocation: _coordinates(
            record.checkOutLatitude,
            record.checkOutLongitude,
          ),
          checkIn: record.checkIn,
          checkOut: record.checkOut,
          pendingSync: record.pendingSync,
        ),
  ];
}

String? _coordinates(double? latitude, double? longitude) =>
    latitude == null || longitude == null
    ? null
    : '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
