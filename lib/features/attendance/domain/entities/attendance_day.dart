final class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.isAbsent,
    this.location,
    this.checkOutLocation,
    this.checkInAt,
    this.checkOutAt,
    this.checkIn = '',
    this.checkOut = '',
    this.pendingSync = false,
  });

  final String? location;
  final String? checkOutLocation;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String date;
  final bool isAbsent;
  final String checkIn;
  final String checkOut;
  final bool pendingSync;
}
