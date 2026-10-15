final class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    this.latitude,
    this.longitude,
    this.pendingSync = false,
  });

  final String date;
  final String checkIn;
  final String checkOut;
  final double? latitude;
  final double? longitude;
  final bool pendingSync;

  bool get isOpen => checkIn.isNotEmpty && checkOut.isEmpty;

  bool get isComplete => checkIn.isNotEmpty && checkOut.isNotEmpty;

  AttendanceRecord copyWith({String? checkOut, bool? pendingSync}) {
    return AttendanceRecord(
      date: date,
      checkIn: checkIn,
      checkOut: checkOut ?? this.checkOut,
      latitude: latitude,
      longitude: longitude,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
