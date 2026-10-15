final class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    this.checkInAt,
    this.checkOutAt,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.latitude,
    this.longitude,
    this.pendingSync = false,
  });

  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String date;
  final String checkIn;
  final String checkOut;
  final double? latitude;
  final double? longitude;
  final bool pendingSync;

  bool get isOpen => checkIn.isNotEmpty && checkOut.isEmpty;

  bool get isComplete => checkIn.isNotEmpty && checkOut.isNotEmpty;

  AttendanceRecord copyWith({
    String? checkOut,
    bool? pendingSync,
    DateTime? checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
  }) {
    return AttendanceRecord(
      date: date,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkIn: checkIn,
      checkOut: checkOut ?? this.checkOut,
      latitude: latitude,
      longitude: longitude,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
