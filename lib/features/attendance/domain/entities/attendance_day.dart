final class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.isAbsent,
    this.checkIn = '',
    this.checkOut = '',
    this.pendingSync = false,
  });

  final String date;
  final bool isAbsent;
  final String checkIn;
  final String checkOut;
  final bool pendingSync;
}
